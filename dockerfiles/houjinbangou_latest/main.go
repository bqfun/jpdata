package main

import (
	"archive/zip"
	"cloud.google.com/go/storage"
	"context"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"regexp"
)

func fetchFileID() string {
	resp, err := http.Get("https://www.houjin-bangou.nta.go.jp/download/zenken/")
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatal(err)
	}

	r := regexp.MustCompile(`<h2 class="title" id="csv-unicode">CSV形式・Unicode</h2>[\S\s]+?<a href="#" onclick="return doDownload\(([0-9]{5})\);">zip [0-9]{3}MB</a>`)
	s := r.FindSubmatch(body)
	return string(s[1])
}

func downloadZip() string {
	id := fetchFileID()
	resp, err := http.PostForm("https://www.houjin-bangou.nta.go.jp/download/zenken/index.html",
		url.Values{"event": {"download"}, "selDlFileNo": {id}})
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()

	name := "zenkoku_all.zip"
	dst, err := os.Create(name)
	if err != nil {
		log.Fatal(err)
	}
	defer dst.Close()

	_, err = io.Copy(dst, resp.Body)
	if err != nil {
		log.Fatal(err)
	}
	return name
}

func unzipCsv(name string) string {
	r, err := zip.OpenReader(name)
	if err != nil {
		log.Fatal(err)
	}
	defer r.Close()

	re := regexp.MustCompile(`00_zenkoku_all_[0-9]{8}.csv`)
	for _, f := range r.File {
		if !re.MatchString(f.Name) {
			continue
		}

		rc, err := f.Open()
		if err != nil {
			log.Fatal(err)
		}
		dst, err := os.Create(f.Name)
		if err != nil {
			log.Fatal(err)
		}

		_, err = io.Copy(dst, rc)
		if err != nil {
			log.Fatal(err)
		}
		rc.Close()
		dst.Close()
		return f.Name
	}
	log.Fatal("the zip file has no csv")
	return ""
}

func upload(bucket string, name string, srcName string) {
	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		log.Fatal(err)
	}
	defer client.Close()

	wc := client.Bucket(bucket).Object(name).NewWriter(ctx)

	f, err := os.Open(srcName)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	if _, err := io.Copy(wc, f); err != nil {
		log.Fatal(err)
	}
	if err := wc.Close(); err != nil {
		log.Fatal(err)
	}
}

func main() {
	bucket := "jpdata-source"
	object := "houjinbangou.csv"

	name := downloadZip()
	csv := unzipCsv(name)
	upload(bucket, object, csv)
}
