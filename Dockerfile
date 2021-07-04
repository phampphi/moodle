FROM erseco/alpine-php7-webserver
LABEL maintainer "Phi Pham <pham.pphi@gmail.com>"
ENV MOODLE_VERSION=3.10.4

COPY --chown=nobody rootfs /

USER root
RUN apk update && \
	apk add --no-cache dcron libcap && \
    chown nobody:nobody /usr/sbin/crond && chmod +x /etc/service/cron/run && \
    setcap cap_setgid=ep /usr/sbin/crond && \
	# Install 'php-redis'
	apk --no-cache add php7-pecl-redis && \
	chmod +x /var/www/html/admin/cli/*

USER nobody

	