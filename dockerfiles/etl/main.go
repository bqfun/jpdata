package main

import (
	"archive/zip"
	"bytes"
	"cloud.google.com/go/storage"
	"context"
	"crypto/md5"
	"encoding/json"
	"errors"
	"fmt"
	"golang.org/x/net/html/charset"
	"io"
	"log"
	"net/http"
	neturl "net/url"
	"os"
	"strconv"
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

func uploadFileIfUpdated(bucket, object string, reader io.Reader) error {
	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		log.Printf("storage.NewClient: %v", err)
		return err
	}
	defer client.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		return err
	}
	o := client.Bucket(bucket).Object(object)
	attrs, err := o.Attrs(ctx)

	if err == nil {
		sum := md5.Sum(data)
		if bytes.Equal(sum[:], attrs.MD5) {
			log.Println("Skipped")
			return nil
		}
	} else if err != storage.ErrObjectNotExist {
		log.Printf("ObjectHandle.Attrs: %v", err)
		return err
	}

	wc := o.NewWriter(ctx)

	if _, err := wc.Write(data); err != nil {
		log.Printf("ObjectHandle.NewWriter: %v", err)
		return err
	}
	if err := wc.Close(); err != nil {
		log.Printf("Writer.Close: %v", err)
		return err
	}
	return nil
}

type Extraction struct {
	Method string
	Url    string
	Body   map[string]string
}
type Transformation struct {
	Call string
	Args map[string]string
}
type Loading struct {
	Bucket string
	Object string
}
type ETL struct {
	Extraction      Extraction
	Transformations []Transformation
	Loading         Loading
}

type Config struct {
	// Job-defined
	taskIndex int
	taskCount int

	// User-defined
	etls []ETL
}

func configFromEnv() (Config, error) {
	// Job-defined
	taskIndex, err := strconv.Atoi(os.Getenv("CLOUD_RUN_TASK_INDEX"))
	if err != nil {
		return Config{}, err
	}
	taskCount, err := strconv.Atoi(os.Getenv("CLOUD_RUN_TASK_COUNT"))
	if err != nil {
		return Config{}, err
	}
	// User-defined
	etls, err := etlToStruct(os.Getenv("ETL"))
	if err != nil {
		return Config{}, err
	}

	config := Config{
		taskIndex: taskIndex,
		taskCount: taskCount,
		etls:      etls,
	}
	return config, nil
}

func etlToStruct(s string) ([]ETL, error) {
	var etls []ETL
	err := json.Unmarshal([]byte(s), &etls)
	for _, etl := range etls {
		if etl.Extraction.Url == "" {
			return etls, errors.New("invalid extraction config")
		}
	}
	return etls, err
}

func main() {
	config, err := configFromEnv()
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Starting Task #%d ...", config.taskIndex)

	for i, etl := range config.etls {
		if i%config.taskCount != config.taskIndex {
			continue
		}

		if etl.Extraction.Method == "" {
			etl.Extraction.Method = http.MethodGet
		}

		reader, err := request(etl.Extraction.Method, etl.Extraction.Url, etl.Extraction.Body)
		if err != nil {
			log.Fatalf("request: %v", err)
		}

		for _, t := range etl.Transformations {
			reader, err = t.transform(reader)
			if err != nil {
				log.Fatalf("uploadFileIfUpdated: %v", err)
			}
		}

		if err := uploadFileIfUpdated(etl.Loading.Bucket, etl.Loading.Object, reader); err != nil {
			log.Fatalf("uploadFileIfUpdated: %v", err)
			return
		}
		reader.Close()
	}

	log.Printf("Completed Task #%d", config.taskIndex)
}

func (t Transformation) transform(reader io.ReadCloser) (io.ReadCloser, error) {
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
