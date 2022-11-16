package main

import (
	"bytes"
	"cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	"cloud.google.com/go/storage"
	"context"
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
)

func download(id string, from time.Time, to time.Time, divide int) []byte {
	req, err := http.NewRequest("GET", "https://api.houjin-bangou.nta.go.jp/4/diff", nil)
	if err != nil {
		panic(err)
	}

	q := req.URL.Query()
	q.Add("id", id)
	q.Add("from", from.Format("2006-01-02"))
	q.Add("to", to.Format("2006-01-02"))
	q.Add("type", "02")
	q.Add("divide", strconv.Itoa(divide))
	req.URL.RawQuery = q.Encode()

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		panic(err)
	}

	bs, err := io.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}

	return bs
}
func getDivisionNumber(b []byte) int {
	r := csv.NewReader(bytes.NewBuffer(b))
	header, err := r.Read()
	if err != nil {
		panic(err)
	}

	divisionNumber, err := strconv.Atoi(header[3])
	if err != nil {
		panic(err)
	}

	return divisionNumber
}

func upload(ctx context.Context, bucket *storage.BucketHandle, name string, src io.Reader) {
	wc := bucket.Object(name).NewWriter(ctx)

	if _, err := io.Copy(wc, src); err != nil {
		panic(err)
	}
	if err := wc.Close(); err != nil {
		panic(err)
	}
}

func downloadThenUpload(ctx context.Context, bucket *storage.BucketHandle, objectPrefix string, id string, from time.Time, divide int) (time.Time, int) {
	to := from.AddDate(0, 0, 49)

	b := download(id, from, to, divide)
	name := fmt.Sprintf("%s%s-%s-%05d.csv", objectPrefix, from.Format("20060102"), to.Format("20060102"), divide)
	upload(ctx, bucket, name, bytes.NewReader(b))

	divisionNumber := getDivisionNumber(b)

	if divide < divisionNumber {
		return from, divide + 1
	}
	return from.AddDate(0, 0, 50), 1
}

func downloadThenUploadAll(name string, objectPrefix string, from time.Time, to time.Time, secretName string) {
	ctx := context.Background()
	clientStorage, err := storage.NewClient(ctx)
	if err != nil {
		panic(err)
	}
	defer clientStorage.Close()
	bucket := clientStorage.Bucket(name)

	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		log.Fatalf("failed to setup client: %v", err)
	}
	defer client.Close()
	accessRequest := &secretmanagerpb.AccessSecretVersionRequest{
		Name: secretName,
	}
	result, err := client.AccessSecretVersion(ctx, accessRequest)
	if err != nil {
		log.Fatalf("failed to access secret version: %v", err)
	}
	id := string(result.Payload.Data)

	divide := 1
	for {
		log.Printf("uploading: %s-%05d\n", from.Format("2006-01-02"), divide)
		from, divide = downloadThenUpload(ctx, bucket, objectPrefix, id, from, divide)
		if from.After(to) {
			break
		}
	}
}

func main() {
	bucket := os.Getenv("BUCKET")
	if bucket == "" {
		log.Fatalf("environment variable 'BUCKET' isn't set")
	}
	objectPrefix := os.Getenv("OBJECT_PREFIX")
	if objectPrefix == "" {
		log.Fatalf("environment variable 'OBJECT_PREFIX' isn't set")
	}
	secretName := os.Getenv("SECRET_NAME")
	if secretName == "" {
		log.Fatalf("environment variable 'SECRET_NAME' isn't set")
	}

	today := time.Now().Truncate(24 * time.Hour)
	init := time.Date(2015, 12, 1, 0, 0, 0, 0, time.Local)

	step := int(today.AddDate(0, 0, -30).Sub(init).Hours()) / 24 / 50
	startDateIn50DayIncrementsIncluding30DaysAgo := init.AddDate(0, 0, 50*step)

	downloadThenUploadAll(
		bucket,
		objectPrefix,
		startDateIn50DayIncrementsIncluding30DaysAgo,
		today,
		secretName,
	)
}
