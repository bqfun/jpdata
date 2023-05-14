package main

import (
	"archive/zip"
	"bufio"
	"bytes"
	"cloud.google.com/go/storage"
	"context"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"golang.org/x/net/html/charset"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
)

type ChainedCloser struct {
	r io.Reader
	c io.Closer
}

func (c ChainedCloser) Read(p []byte) (n int, err error) { return c.r.Read(p) }
func (c ChainedCloser) Close() error                     { return c.c.Close() }

type HTTPExtractor struct {
	method string
	url    string
	body   string
}

func (e HTTPExtractor) Extract() (io.ReadCloser, error) {
	req, err := http.NewRequest(e.method, e.url, strings.NewReader(e.body))
	if err != nil {
		log.Printf("http.NewRequest: %v", err)
		return nil, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Printf("http.DefaultClient.Do: %v", err)
		return nil, err
	}
	if res.StatusCode > 299 {
		io.Copy(io.Discard, res.Body)
		res.Body.Close()
		return nil, fmt.Errorf("Response failed with status code: %d\n", res.StatusCode)
	}

	return res.Body, nil
}

type Tweaker interface {
	tweak(reader io.ReadCloser) (io.ReadCloser, error)
}

type CharsetConverter struct {
	label string
}

func (t CharsetConverter) tweak(reader io.ReadCloser) (io.ReadCloser, error) {
	nr, err := charset.NewReaderLabel(t.label, reader)
	if err != nil {
		return nil, err
	}
	return ChainedCloser{nr, reader}, nil
}

type ZipFileOpener struct{}

func (t ZipFileOpener) tweak(reader io.ReadCloser) (io.ReadCloser, error) {
	b, err := io.ReadAll(reader)
	if err != nil {
		return nil, err
	}
	reader.Close()

	r, err := zip.NewReader(bytes.NewReader(b), int64(len(b)))

	if err != nil {
		return nil, err
	}

	if len(r.File) == 0 {
		return nil, nil
	}
	return r.File[0].Open()
}

type CloudStorageLoader struct {
	bucketName string
	objectName string
}

func (l CloudStorageLoader) load(r io.Reader) ([]string, error) {
	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		log.Printf("storage.NewClient: %v", err)
		return nil, err
	}
	defer client.Close()

	o := client.Bucket(l.bucketName).Object(l.objectName)
	wc := o.NewWriter(ctx)
	br := bufio.NewReader(io.TeeReader(r, wc))
	bom, err := br.Peek(3)
	if err != nil {
		log.Printf("bufio.Reader.Peek: %v", err)
		return nil, err
	}
	if bom[0] == 0xEF && bom[1] == 0xBB && bom[2] == 0xBF {
		br.Discard(3)
	}
	cr := csv.NewReader(br)
	cr.LazyQuotes = true
	header, err := cr.Read()
	if err != nil {
		log.Printf("csv.Reader.Read: %v", err)
		return nil, err
	}
	io.Copy(io.Discard, br)

	if err := wc.Close(); err != nil {
		log.Printf("Writer.Close: %v", err)
		return nil, err
	}
	return header, nil
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

type Input struct {
	RequestId          string            `json:"requestId"`
	Caller             string            `json:"caller"`
	SessionUser        string            `json:"sessionUser"`
	UserDefinedContext map[string]string `json:"userDefinedContext"`
	Calls              [][]any           `json:"calls"`
}

func parseCall(call []any) (*HTTPExtractor, []Tweaker, *CloudStorageLoader, error) {
	if len(call) != 7 {
		return nil, nil, nil, fmt.Errorf("invalid number of input fields provided.  expected 7, got  %d", len(call))
	}
	method, ok := call[0].(string)
	if !ok {
		return nil, nil, nil, fmt.Errorf("invalid method type. expected string")
	}
	url, ok := call[1].(string)
	if !ok {
		return nil, nil, nil, fmt.Errorf("invalid url type. expected string")
	}
	body, ok := call[2].(string)
	if !ok {
		return nil, nil, nil, fmt.Errorf("invalid body type. expected string")
	}
	isZip, ok := call[3].(bool)
	if !ok {
		return nil, nil, nil, fmt.Errorf("invalid unzip type. expected bool")
	}
	label, ok := call[4].(string)
	if !ok {
		return nil, nil, nil, fmt.Errorf("invalid charset type. expected string")
	}
	bucket, ok := call[5].(string)
	if !ok {
		return nil, nil, nil, fmt.Errorf("invalid bucket type. expected string")
	}
	object, ok := call[6].(string)
	if !ok {
		return nil, nil, nil, fmt.Errorf("invalid object type. expected string")
	}

	var tweakers []Tweaker
	if isZip {
		tweakers = append(tweakers, ZipFileOpener{})
	}
	if strings.ToLower(strings.TrimSpace(label)) != "utf-8" {
		tweakers = append(tweakers, CharsetConverter{label})
	}

	return &HTTPExtractor{method, url, body}, tweakers, &CloudStorageLoader{bucket, object}, nil
}

func returnErrorMessage(w http.ResponseWriter, statusCode int, errorMessage error) {
	data, err := json.Marshal(map[string]string{"errorMessage": errorMessage.Error()})
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	if err != nil {
		fmt.Fprint(w, `{"errorMessage": "json.Marshal Failed"}`)
		return
	}
	fmt.Fprint(w, data)
}

type Reply struct {
	Header []string `json:"header"`
}

func handler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		returnErrorMessage(w, http.StatusBadRequest, fmt.Errorf("method Not Allowed: %v", r.Method))
		return
	}
	var input Input

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		returnErrorMessage(w, http.StatusBadRequest, fmt.Errorf("json.NewDecoder.Decode: %v", err))
		return
	}

	replies := make([]Reply, len(input.Calls))
	for i, call := range input.Calls {
		extractor, tweakers, loader, err := parseCall(call)
		if err != nil {
			returnErrorMessage(w, http.StatusBadGateway, err)
			return
		}
		reader, err := extractor.Extract()
		if err != nil {
			returnErrorMessage(w, http.StatusBadGateway, err)
			return
		}
		for _, tweaker := range tweakers {
			reader, err = tweaker.tweak(reader)
			if err != nil {
				returnErrorMessage(w, http.StatusBadGateway, err)
				return
			}
		}

		header, err := loader.load(reader)
		if err != nil {
			returnErrorMessage(w, http.StatusBadGateway, err)
			return
		}

		if err != nil {
			returnErrorMessage(w, http.StatusBadGateway, err)
			return
		}
		replies[i] = Reply{header}
	}

	data, err := json.Marshal(map[string][]Reply{"replies": replies})
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err != nil {
		fmt.Fprint(w, `{"errorMessage": "json.Marshal Failed"}`)
		return
	}
	w.Write(data)
}
