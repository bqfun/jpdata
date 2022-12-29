package main

import (
	"archive/zip"
	"bytes"
	"cloud.google.com/go/storage"
	"context"
	"crypto/md5"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

func request(method, url string) (*http.Response, error) {
	req, err := http.NewRequest(method, url, nil)
	if err != nil {
		log.Printf("http.NewRequest: %v", err)
		return nil, err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Printf("http.DefaultClient.Do: %v", err)
		return nil, err
	}
	return resp, nil
}

func unzip(body io.Reader) error {
	f, err := os.CreateTemp("", "")
	if err != nil {
		log.Printf("os.CreateTemp: %v", err)
		return err
	}
	defer os.Remove(f.Name())
	if _, err := io.Copy(f, body); err != nil {
		log.Printf("io.Copy: %v", err)
		return err
	}

	r, err := zip.OpenReader(f.Name())
	if err != nil {
		log.Printf("zip.OpenReader: %v", err)
		return err
	}

	for _, f := range r.File {
		err := func(f *zip.File) error {
			src, err := f.Open()
			if err != nil {
				log.Printf("File.Open: %v", err)
				return err
			}

			dst, err := os.Create(f.Name)
			if err != nil {
				log.Printf("os.Create: %v", err)
				return err
			}
			defer dst.Close()
			if _, err := io.Copy(dst, src); err != nil {
				log.Printf("io.Copy: %v", err)
				return err
			}
			return nil
		}(f)
		if err != nil {
			return err
		}
	}
	return nil
}

func md5Sum(name string) ([]byte, error) {
	f, err := os.Open(name)
	if err != nil {
		log.Printf("os.Open: %v", err)
		return nil, err
	}
	defer f.Close()

	h := md5.New()
	if _, err := io.Copy(h, f); err != nil {
		log.Printf("io.Copy: %v", err)
		return nil, err
	}

	return h.Sum(nil), nil
}

func uploadFileIfUpdated(bucket, object, name string) error {
	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		log.Printf("storage.NewClient: %v", err)
		return err
	}
	defer client.Close()

	f, err := os.Open(name)
	if err != nil {
		log.Printf("os.Open: %v", err)
		return err
	}
	defer f.Close()

	o := client.Bucket(bucket).Object(object)
	attrs, err := o.Attrs(ctx)
	if err == nil {
		sum, err := md5Sum(name)
		if err != nil {
			return err
		}
		if bytes.Equal(sum, attrs.MD5) {
			log.Println("Skipped")
			return nil
		}
	} else if err != storage.ErrObjectNotExist {
		log.Printf("ObjectHandle.Attrs: %v", err)
		return err
	}

	wc := o.NewWriter(ctx)
	if _, err = io.Copy(wc, f); err != nil {
		log.Printf("ObjectHandle.NewWriter: %v", err)
		return err
	}
	if err := wc.Close(); err != nil {
		log.Printf("Writer.Close: %v", err)
		return err
	}
	return nil
}

func main() {
	log.Print("starting server...")
	http.HandleFunc("/", handler)

	// Determine port for HTTP service.
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
		log.Printf("defaulting to port %s", port)
	}

	// Start HTTP server.
	log.Printf("listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	var d struct {
		Extraction struct {
			Method string
			Url    string
		}
		Transformations []struct {
			Call string
		}
		Loading struct {
			Bucket string
			Object string
			Name   string
		}
	}

	if err := json.NewDecoder(r.Body).Decode(&d); err != nil {
		log.Printf("json.NewDecoder: %v", err)
		http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
		return
	}
	resp, err := request(d.Extraction.Method, d.Extraction.Url)
	if err != nil {
		log.Printf("request: %v", err)
		http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
		return
	}
	defer resp.Body.Close()

	for _, transformation := range d.Transformations {
		func() {
			if transformation.Call == "unzip" {
				err := unzip(resp.Body)
				if err != nil {
					log.Printf("unzip: %v", err)
					http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
					return
				}
			} else {
				log.Printf("Unsupported call: %v", transformation.Call)
				http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
				return
			}
		}()
	}

	if err := uploadFileIfUpdated(d.Loading.Bucket, d.Loading.Object, d.Loading.Name); err != nil {
		log.Printf("uploadFileIfUpdated: %v", err)
		http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
		return
	}

	fmt.Fprintf(w, "Successfully loaded data from %s to gs://%s/%s.", d.Extraction.Url, d.Loading.Bucket, d.Loading.Object)
}
