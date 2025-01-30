package main

import (
	"github.com/webview/webview"
)

func main() {
	// Create a new WebView instance
	w := webview.New(true)
	defer w.Destroy()
	
	w.SetTitle("Go WebView Example")
	w.SetSize(800, 600, webview.HintNone)

	// Load a website
	w.Navigate("https://www.rust-lang.org") // Replace with any URL

	// Run the event loop
	w.Run()
}
