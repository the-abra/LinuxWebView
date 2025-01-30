source lib.sh.d/log.lib

if ! [[ $(command -v go) ]]; then
    (pacman install git go -yq) ||  (log.error "Faild to install golang(go)" && exit 1)
fi

go mod tidy || (go env -w GOPROXY=direct && go get github.com/webview/webview)
go run main.go
