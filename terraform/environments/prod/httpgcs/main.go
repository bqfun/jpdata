package httpgcs

import (
	"cloud.google.com/go/storage"
	"context"
	"encoding/json"
	"fmt"
	"golang.org/x/text/encoding/japanese"
	"golang.org/x/text/transform"
	"io"
	"log"
	"net/http"
	"strings"
)

type D struct {
	Method     string            `json:"method"`
	Url        string            `json:"url"`
	Body       string            `json:"body"`
	Headers    map[string]string `json:"headers"`
	IsShiftJIS bool              `json:"is_shiftjis"`
	Bucket     string            `json:"bucket"`
	Object     string            `json:"object"`
}

func (d D) downloadThenUpload() error {
	req, err := http.NewRequest(d.Method, d.Url, strings.NewReader(d.Body))
	if err != nil {
		return err
	}
	for key, value := range d.Headers {
		req.Header.Set(key, value)
	}

	res, err := http.DefaultClient.Do(req)

	if err != nil {
		return fmt.Errorf("http.PostForm: %v", err)
	}
	defer res.Body.Close()
	if res.StatusCode != 200 {
		return fmt.Errorf("Response failed with status code: %d\n", res.StatusCode)
	}

	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		return fmt.Errorf("storage.NewClient: %v", err)
	}
	defer client.Close()

	// Upload an object with storage.Writer.
	wc := client.Bucket(d.Bucket).Object(d.Object).NewWriter(ctx)

	var r io.Reader = res.Body
	if d.IsShiftJIS {
		r = transform.NewReader(res.Body, japanese.ShiftJIS.NewDecoder())
	}

	if _, err = io.Copy(wc, r); err != nil {
		return fmt.Errorf("io.Copy: %v", err)
	}
	// Data can continue to be added to the file until the writer is closed.
	if err := wc.Close(); err != nil {
		return fmt.Errorf("Writer.Close: %v", err)
	}

	return nil
}

func Handler(w http.ResponseWriter, r *http.Request) {
	var d D

	if err := json.NewDecoder(r.Body).Decode(&d); err != nil {
		log.Printf("json.NewDecoder: %v", err)
		http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
		return
	}

	if err := d.downloadThenUpload(); err != nil {
		log.Printf("streamFileUpload: %v", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}
	fmt.Fprint(w, "uploaded")
}
