![Logo](img/logo.png)

![Screenshot](img/screenshot.gif)

A mobile file explorer that can upload and download files from a remote file server

## Install

Download [airlink.apk](https://github.com/synw/airlink/releases/download/0.1.0/airlink.apk) for Android or compile the source with Flutter.

## Server

Download [airlink_server](https://github.com/synw/airlink/releases/download/0.1.0/airlink_server) for Linux or compile with Go

## Config

Server: place a `config.json` file next to the binary:

   ```json
   {
      "port": "8084",
      "apiKey": "API_KEY"
   }
   ```

Client: go to the settings in the app to set the server parameters