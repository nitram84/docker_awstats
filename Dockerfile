FROM httpd:2.4.57-alpine

ARG MOD_PERL_VERSION=2.0.12
ARG MOD_PERL_SHA=f5b821b59b0fdc9670e46ed0fcf32d8911f25126189a8b68c1652f9221eee269

RUN apk add --no-cache gettext \
    && apk add --no-cache --virtual .build-dependencies apr-dev apr-util-dev gcc libc-dev make wget perl-dev \
    && cd /tmp \
    && wget https://www-eu.apache.org/dist/perl/mod_perl-${MOD_PERL_VERSION}.tar.gz \
    && echo "${MOD_PERL_SHA}  mod_perl-${MOD_PERL_VERSION}.tar.gz" | sha256sum -c \
    && tar xf mod_perl-${MOD_PERL_VERSION}.tar.gz \
    && cd mod_perl-${MOD_PERL_VERSION} \
    && perl Makefile.PL MP_APXS=/usr/local/apache2/bin/apxs MP_APR_CONFIG=/usr/bin/apr-1-config --cflags --cppflags --includes \
    && make -j4 \
    && mv src/modules/perl/mod_perl.so /usr/local/apache2/modules/ \
    && echo 'LoadModule perl_module modules/mod_perl.so' >> /usr/local/apache2/conf/httpd.conf \
    && echo 'Include conf/awstats_httpd.conf' >> /usr/local/apache2/conf/httpd.conf \
    && cd .. \
    && rm -rf ./mod_perl-${MOD_PERL_VERSION}* \
    && apk del --no-cache .build-dependencies

ARG TZDATA_VERSION=2023c-r1
ARG AWSTATS_VERSION=7.9-r0

RUN apk add --no-cache awstats=${AWSTATS_VERSION} tzdata=${TZDATA_VERSION}

COPY awstats_env.conf /etc/awstats/
COPY awstats_httpd.conf /usr/local/apache2/conf/
COPY entrypoint.sh /usr/local/bin/

ENV AWSTATS_CONF_LOGFILE="/var/local/log/access.log"
ENV AWSTATS_CONF_LOGFORMAT="%host %other %logname %time1 %methodurl %code %bytesd %refererquot %uaquot"
ENV AWSTATS_CONF_SITEDOMAIN="my_website"
ENV AWSTATS_CONF_HOSTALIASES="localhost 127.0.0.1 REGEX[^.*$]"
ENV AWSTATS_CONF_INCLUDE="."

ENTRYPOINT ["entrypoint.sh"]
CMD ["httpd-foreground"]
