FROM alpine:3.10 AS perl

RUN apk add --no-cache gcc git linux-headers make musl-dev openssl-dev perl

RUN git clone git://github.com/rakudo/rakudo \
 && cd rakudo                                \
 && git checkout 2019.07.1                   \
 && CFLAGS=-flto ./Configure.pl              \
    --gen-moar                               \
    --moar-option=--ar=gcc-ar                \
    --prefix=/usr                            \
 && make -j`nproc` install                   \
 && strip /usr/bin/perl6

FROM scratch AS service

COPY --from=perl /lib/ld-musl-x86_64.so.1  /lib/
COPY --from=perl /usr/bin/perl6            /usr/bin/
COPY --from=perl /usr/lib/libcrypto.so.1.1 \
                 /usr/lib/libmoar.so       \
                 /usr/lib/libssl.so        /usr/lib/
COPY --from=perl /usr/share/nqp            /usr/share/nqp
COPY --from=perl /usr/share/perl6          /usr/share/perl6

COPY group passwd /etc/
COPY static       /static/
COPY vendor       /usr/share/perl6/vendor/
COPY views        /views/
COPY service.p6   /

USER nobody

CMD ["perl6", "service.p6"]

FROM perl AS deps

RUN git clone git://github.com/ugexe/zef \
 && cd zef                               \
 && perl6 -I. bin/zef --/test install .

ENV PATH /usr/share/perl6/site/bin:$PATH

ENTRYPOINT ["zef", "--/test", "--to=vendor"]
