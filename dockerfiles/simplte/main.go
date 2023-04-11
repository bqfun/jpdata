package main

import (
	"archive/zip"
	"bytes"
	"cloud.google.com/go/storage"
	"context"
	"crypto/md5"
	"encoding/json"
	"fmt"
	"golang.org/x/net/html/charset"
	"io"
	"log"
	"net/http"
	neturl "net/url"
	"os"
	"strings"
)

type ChainedCloser struct {
	r io.Reader
	c io.Closer
}

func (c ChainedCloser) Read(p []byte) (n int, err error) { return c.r.Read(p) }
func (c ChainedCloser) Close() error                     { return c.c.Close() }

func request(method, url string, body map[string]string) (io.ReadCloser, error) {
	v := neturl.Values{}
	for key, value := range body {
		v.Set(key, value)
	}
	req, err := http.NewRequest(method, url, strings.NewReader(v.Encode()))
	if err != nil {
		log.Printf("http.NewRequest: %v", err)
		return nil, err
	}
	if len(v) != 0 {
		req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Printf("http.DefaultClient.Do: %v", err)
		return nil, err
	}
	if resp.StatusCode > 299 {
		return nil, fmt.Errorf("Response failed with status code: %d and\nbody: %s\n", resp.StatusCode, body)
	}

	return resp.Body, nil
}

func convert(label string, r io.ReadCloser) (io.Reader, error) {
	return charset.NewReaderLabel(label, r)
}

func unzip(reader io.ReadCloser) (io.ReadCloser, error) {
	b := bytes.NewBuffer([]byte{})
	size, err := io.Copy(b, reader)
	if err != nil {
		return nil, err
	}
	reader.Close()

	br := bytes.NewReader(b.Bytes())
	r, err := zip.NewReader(br, size)
	if err != nil {
		return nil, err
	}

	if len(r.File) == 0 {
		return nil, nil
	}
	return r.File[0].Open()
}

func uploadFileIfUpdated(bucket, object string, reader io.Reader) (bool, error) {
	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		log.Printf("storage.NewClient: %v", err)
		return false, err
	}
	defer client.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		return false, err
	}
	o := client.Bucket(bucket).Object(object)
	attrs, err := o.Attrs(ctx)

	if err == nil {
		sum := md5.Sum(data)
		if bytes.Equal(sum[:], attrs.MD5) {
			log.Println("Skipped")
			return false, nil
		}
	} else if err != storage.ErrObjectNotExist {
		log.Printf("ObjectHandle.Attrs: %v", err)
		return false, err
	}

	wc := o.NewWriter(ctx)

	if _, err := wc.Write(data); err != nil {
		log.Printf("ObjectHandle.NewWriter: %v", err)
		return false, err
	}
	if err := wc.Close(); err != nil {
		log.Printf("Writer.Close: %v", err)
		return false, err
	}
	return true, nil
}

func main() {
	log.Print("starting server...")
	http.HandleFunc("/", handler)

	// Determine port for HTTP service.
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Printf("defaulting to port %s", port)
	}

	// Start HTTP server.
	log.Printf("listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func (t Tweak) tweak(reader io.ReadCloser) (io.ReadCloser, error) {
	var nextReader io.ReadCloser
	var err error

	if t.Call == "unzip" {
		nextReader, err = unzip(reader)
	} else if t.Call == "convert" {
		var nr io.Reader
		nr, err = convert(t.Args["charset"], reader)
		nextReader = ChainedCloser{nr, reader}
	} else {
		return nil, fmt.Errorf("unsupported call: %v", t.Call)
	}

	if err != nil {
		log.Printf("call transformers: %v", err)
		return nil, err
	}
	return nextReader, nil
}

type Extraction struct {
	Method string
	Url    string
	Body   map[string]string
}
type Tweak struct {
	Call string
	Args map[string]string
}
type Loading struct {
	Bucket string
	Object string
}

func handler(w http.ResponseWriter, r *http.Request) {
	var d struct {
		Extraction Extraction
		Tweaks     []Tweak
		Loading    Loading
	}

	if err := json.NewDecoder(r.Body).Decode(&d); err != nil {
		log.Printf("json.NewDecoder: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, `{"error": "Internal Server Error"}`)
		return
	}
	reader, err := request(d.Extraction.Method, d.Extraction.Url, d.Extraction.Body)
	fmt.Printf("%v", d.Extraction.Body)
	if err != nil {
		log.Printf("request: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, `{"error": "Internal Server Error"}`)
		return
	}

	for _, t := range d.Tweaks {
		reader, err = t.tweak(reader)
		if err != nil {
			log.Printf("tweak: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(w, `{"error": "Internal Server Error"}`)
			return
		}
	}

	isUpdated, err := uploadFileIfUpdated(d.Loading.Bucket, d.Loading.Object, reader)
	if err != nil {
		log.Printf("uploadFileIfUpdated: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, `{"error": "Internal Server Error"}`)
		return
	}
	reader.Close()
	fmt.Fprintf(w, `{"is_updated": %t}`, isUpdated)
}
