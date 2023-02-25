package main

import (
	"archive/zip"
	"bufio"
	"bytes"
	"cloud.google.com/go/storage"
	"context"
	"crypto/md5"
	"encoding/json"
	"fmt"
	"golang.org/x/text/encoding/japanese"
	"golang.org/x/text/transform"
	"io"
	"log"
	"net/http"
	neturl "net/url"
	"os"
	"strings"
)

func request(method, url string, body map[string]string) (string, error) {
	v := neturl.Values{}
	for key, value := range body {
		v.Set(key, value)
	}
	req, err := http.NewRequest(method, url, strings.NewReader(v.Encode()))
	if err != nil {
		log.Printf("http.NewRequest: %v", err)
		return "", err
	}
	if len(v) != 0 {
		req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Printf("http.DefaultClient.Do: %v", err)
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode > 299 {
		return "", fmt.Errorf("Response failed with status code: %d and\nbody: %s\n", resp.StatusCode, body)
	}

	f, err := os.CreateTemp("", "")
	if err != nil {
		log.Printf("os.CreateTemp: %v", err)
		return "", err
	}
	defer f.Close()
	if _, err := io.Copy(f, resp.Body); err != nil {
		log.Printf("io.Copy: %v", err)
		return "", err
	}
	return f.Name(), nil
}

func fromShiftJIS(name string) (string, error) {
	f, err := os.Open(name)
	if err != nil {
		log.Printf("os.Open: %v", err)
		return "", err
	}
	defer f.Close()

	dst, err := os.CreateTemp("", "")
	if err != nil {
		log.Printf("os.CreateTemp: %v", err)
		return "", err
	}
	defer dst.Close()

	src := transform.NewReader(f, japanese.ShiftJIS.NewDecoder())
	if _, err := io.Copy(dst, src); err != nil {
		log.Printf("io.Copy: %v", err)
		return "", err
	}
	return dst.Name(), nil
}

func unzip(name string) ([]string, error) {
	r, err := zip.OpenReader(name)
	if err != nil {
		log.Printf("zip.OpenReader: %v", err)
		return nil, err
	}

	var names []string
	for _, f := range r.File {
		name, err := func(f *zip.File) (string, error) {
			src, err := f.Open()
			if err != nil {
				log.Printf("File.Open: %v", err)
				return "", err
			}
			defer src.Close()

			dst, err := os.Create(f.Name)
			if err != nil {
				log.Printf("os.Create: %v", err)
				return "", err
			}
			defer dst.Close()
			if _, err := io.Copy(dst, src); err != nil {
				log.Printf("io.Copy: %v", err)
				return "", err
			}
			return f.Name, nil
		}(f)
		if err != nil {
			return nil, err
		}
		names = append(names, name)
	}
	return names, nil
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

func replaceFirstLine(source string, newFirstLine string) (string, error) {
	src, err := os.Open(source)
	if err != nil {
		log.Printf("os.Open: %v", err)
		return "", err
	}

	defer src.Close()
	r := bufio.NewReader(src)
	if _, _, err = r.ReadLine(); err != nil {
		log.Printf("r.ReadLine: %v", err)
		return "", err
	}

	dst, err := os.CreateTemp("", "")
	if err != nil {
		log.Printf("os.CreateTemp: %v", err)
		return "", err
	}
	defer dst.Close()

	mr := io.MultiReader(strings.NewReader(newFirstLine+"\n"), r)
	if _, err := io.Copy(dst, mr); err != nil {
		log.Printf("io.Copy: %v", err)
		return "", err
	}

	return dst.Name(), nil
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

func (t Transformation) transform(name string) ([]string, error) {
	transformers := map[string]func(string) ([]string, error){
		"unzip": unzip,
		"fromShiftJIS": func(s string) ([]string, error) {
			n, err := fromShiftJIS(s)
			return []string{n}, err
		},
		"replaceFirstLine": func(s string) ([]string, error) {
			n, err := replaceFirstLine(s, t.NewFirstLine)
			return []string{n}, err
		},
	}
	f, ok := transformers[t.Call]
	if !ok {
		return nil, fmt.Errorf("unsupported call: %v", t.Call)
	}
	ns, err := f(name)
	if err != nil {
		log.Printf("call transformers: %v", err)
		return nil, err
	}
	return ns, nil
}

func transformThenRemove(names []string, t Transformation) ([]string, error) {
	var nextNames []string
	for _, name := range names {
		ns, err := t.transform(name)
		if err != nil {
			log.Printf("t.transform: %v", err)
			return nil, err
		}
		nextNames = append(nextNames, ns...)

		os.Remove(name)
	}
	return nextNames, nil
}

type Transformation struct {
	Call         string
	NewFirstLine string
}

func handler(w http.ResponseWriter, r *http.Request) {
	var d struct {
		Extraction struct {
			Method string
			Url    string
			Body   map[string]string
		}
		Transformations []Transformation
		Loading         struct {
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
	name, err := request(d.Extraction.Method, d.Extraction.Url, d.Extraction.Body)
	fmt.Printf("%v", d.Extraction.Body)
	if err != nil {
		log.Printf("request: %v", err)
		http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
		return
	}
	defer os.Remove(name)

	names := []string{name}
	for _, transformation := range d.Transformations {
		names, err = transformThenRemove(names, transformation)
		if err != nil {
			http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
			return
		}
	}

	if d.Loading.Name == "" {
		if len(names) != 1 {
			log.Printf("Loading.Name not specified")
			http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
			return
		}
		d.Loading.Name = names[0]
	}

	if err := uploadFileIfUpdated(d.Loading.Bucket, d.Loading.Object, d.Loading.Name); err != nil {
		log.Printf("uploadFileIfUpdated: %v", err)
		http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
		return
	}

	fmt.Fprintf(w, "Successfully loaded data from %s to gs://%s/%s.", d.Extraction.Url, d.Loading.Bucket, d.Loading.Object)

	for _, name := range names {
		os.Remove(name)
	}
}
