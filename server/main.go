package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"path"
	"path/filepath"

	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
	"github.com/mdp/qrterminal"
	qrcode "github.com/skip2/go-qrcode"
	"github.com/spf13/viper"
)

var genConfCode = flag.Bool("c", false, "Generate autoconfig qr code")
var genConfCodeImg = flag.Bool("ci", false, "Generate autoconfig qr code image")

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

type Config struct {
	Name     string `json:"name"`
	URL      string `json:"url"`
	APIKey   string `json:"apiKey"`
	Port     string `json:"port"`
	Protocol string `json:"protocol"`
}

func getIPAddress() net.IP {
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()
	localAddr := conn.LocalAddr().(*net.UDPAddr)
	return localAddr.IP
}

func getConf() (Config, error) {
	viper.SetConfigName("config")
	viper.AddConfigPath(".")
	config := Config{}
	err := viper.ReadInConfig()
	if err != nil {
		return config, err
	}
	name := viper.Get("name").(string)
	apiKey := viper.Get("apiKey").(string)
	port := viper.Get("port").(string)
	protocol := viper.Get("protocol").(string)
	config = Config{
		Name:     name,
		URL:      getIPAddress().String(),
		APIKey:   apiKey,
		Port:     port,
		Protocol: protocol,
	}
	return config, nil
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
	flag.Parse()

	config, err := getConf()
	if err != nil {
		log.Fatal(err)
	}

	if *genConfCodeImg == true {
		b, _ := json.Marshal(&config)
		data := string(b)
		err := qrcode.WriteFile(data,
			qrcode.Medium, 256, "qr_config.png")
		if err != nil {
			log.Fatal(err)
		}
		return
	} else if *genConfCode == true {
		qrConfig := qrterminal.Config{
			Level:     qrterminal.M,
			Writer:    os.Stdout,
			BlackChar: qrterminal.BLACK,
			WhiteChar: qrterminal.WHITE,
			QuietZone: 5,
		}
		b, _ := json.Marshal(&config)
		data := string(b)
		qrterminal.GenerateWithConfig(data, qrConfig)
		return
	}

	k := config.APIKey
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

	e.Logger.Fatal(e.Start(":" + config.Port))
}
