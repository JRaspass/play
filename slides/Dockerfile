FROM golang:1.13.1-buster

RUN CGO_ENABLED=0 go get -ldflags -s golang.org/x/tools/cmd/present

FROM scratch

COPY --from=0 /go/src/golang.org/x/tools/cmd/present/static \
              /go/src/golang.org/x/tools/cmd/present/static/

COPY --from=0 /go/src/golang.org/x/tools/cmd/present/templates \
              /go/src/golang.org/x/tools/cmd/present/templates/

COPY --from=0 /go/bin/present /bin/

COPY * /slides/

CMD ["present", "-content", "slides", "-http", ":1337", "-play", "false"]
