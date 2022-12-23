package main

import (
	"archive/zip"
	"bytes"
	"cloud.google.com/go/storage"
	"context"
	"crypto/md5"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
)

func request(method, url string) *http.Response {
	req, err := http.NewRequest(method, url, nil)
	if err != nil {
		panic(err)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		panic(err)
	}
	return resp
}

func unzip(body io.Reader) {
	f, err := os.CreateTemp("", "")
	if err != nil {
		panic(err)
	}
	defer os.Remove(f.Name())
	if _, err := io.Copy(f, body); err != nil {
		panic(err)
	}

	r, err := zip.OpenReader(f.Name())
	if err != nil {
		panic(err)
	}

	for _, f := range r.File {
		func(f *zip.File) {
			src, err := f.Open()
			if err != nil {
				panic(err)
			}

			dst, err := os.Create(f.Name)
			if err != nil {
				panic(err)
			}
			defer dst.Close()
			if _, err := io.Copy(dst, src); err != nil {
				panic(err)
			}
		}(f)
	}
}

func md5Sum(name string) []byte {
	f, err := os.Open(name)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	h := md5.New()
	if _, err := io.Copy(h, f); err != nil {
		panic(err)
	}

	return h.Sum(nil)
}

func uploadFileIfNeeded(bucket, object, name string) {
	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		panic(err)
	}
	defer client.Close()

	f, err := os.Open(name)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	o := client.Bucket(bucket).Object(object)
	attrs, err := o.Attrs(ctx)
	if err == nil {
		sum := md5Sum(name)
		if bytes.Equal(sum, attrs.MD5) {
			log.Println("Skipped")
			return
		}
	} else if err != storage.ErrObjectNotExist {
		panic(err)
	}

	wc := o.NewWriter(ctx)
	if _, err = io.Copy(wc, f); err != nil {
		panic(err)
	}
	if err := wc.Close(); err != nil {
		panic(err)
	}
}

type Config struct {
	Extract struct {
		Method string
		Url    string
	}
	Transform []struct {
		Call string
	}
	Load struct {
		Bucket string
		Object string
		Name   string
	}
}

func main() {
	var c Config
	if err := json.Unmarshal([]byte(`{
		"extract": {
			"method": "GET",
			"url": "https://gov-csv-export-public.s3.ap-northeast-1.amazonaws.com/mt_town/mt_town_all.csv.zip"
		},
		"transform": [
			{
				"call": "unzip"
			}
		],
		"load": {
			"bucket": "jpdata-source-eventarc",
			"object": "base_registry_address/mt_town_all.csv",
			"name": "mt_town_all.csv"
		}
	}`), &c); err != nil {
		panic(err)
	}

	resp := request(c.Extract.Method, c.Extract.Url)
	defer resp.Body.Close()

	for _, v := range c.Transform {
		func() {
			if v.Call == "unzip" {
				unzip(resp.Body)
			}
		}()
	}

	uploadFileIfNeeded(c.Load.Bucket, c.Load.Object, c.Load.Name)
}
