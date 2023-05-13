FROM alpine AS cosign-test-1
ENV FOO=123

FROM cosign-test-1 AS cosign-test-2
ENV BAR=456
RUN echo $FOO $BAR > /msg.txt

FROM scratch AS cosign-test-3
COPY --from=cosign-test-2 /msg.txt /
