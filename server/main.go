package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"path"
	"path/filepath"

	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
	"github.com/spf13/viper"
)

type File struct {
	Name string `json:"name"`
	Size int64  `json:"size"`
}

type Directory struct {
	Name string `json:"name"`
}

type DirectoryListing struct {
	Files       []File      `json:"files"`
	Directories []Directory `json:"directories"`
}

func getConf() (string, string, error) {
	viper.SetConfigName("config")
	viper.AddConfigPath(".")
	err := viper.ReadInConfig()
	if err != nil {
		return "", "", err
	}
	apiKey := viper.Get("apiKey").(string)
	port := viper.Get("port").(string)
	return port, apiKey, nil
}

func upload(c echo.Context) error {
	file, err := c.FormFile("file")
	if err != nil {
		return err
	}
	src, err := file.Open()
	if err != nil {
		return err
	}
	defer src.Close()

	// Destination
	dst, err := os.Create(file.Filename)
	if err != nil {
		return err
	}
	defer dst.Close()

	// Copy
	if _, err = io.Copy(dst, src); err != nil {
		return err
	}

	return c.HTML(http.StatusOK, fmt.Sprintf("<p>File %s uploaded successfully", file.Filename))
}

func readDir(root string) (DirectoryListing, error) {
	var files = []File{}
	var dirs = []Directory{}
	var listing DirectoryListing
	fileInfo, err := ioutil.ReadDir(root)
	if err != nil {
		return listing, err
	}

	for _, file := range fileInfo {
		if file.IsDir() == true {
			dirs = append(dirs, Directory{Name: file.Name()})
		} else {
			//fmt.Println(file.Size)
			files = append(files, File{Name: file.Name(), Size: file.Size()})
		}
	}
	listing = DirectoryListing{Files: files, Directories: dirs}
	return listing, nil
}

func main() {

	port, apiKey, err := getConf()
	if err != nil {
		panic(err)
	}
	k := apiKey
	e := echo.New()
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.KeyAuth(func(key string, c echo.Context) (bool, error) {
		return key == k, nil
	}))

	e.Static("/", "static")
	e.POST("/ls", func(c echo.Context) error {
		dirpath := c.FormValue("path")
		p := filepath.Join("static", path.Clean("/"+dirpath))

		listing, err := readDir(p)
		if err != nil {
			fmt.Println("Can not read dir")
		}

		return c.JSON(http.StatusOK, listing)
	})
	e.POST("/upload", upload)

	e.Logger.Fatal(e.Start(":" + port))
}
