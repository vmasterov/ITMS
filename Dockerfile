FROM hub.b1-it.ru/node:18.16.1-alpine as builder

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV} \
    NODE_OPTIONS="--max_old_space_size=8192"

ARG WORKDIR=/usr/src/app

WORKDIR $WORKDIR

RUN corepack enable && corepack prepare pnpm@8.6.5 --activate

COPY package.json pnpm-lock.yaml ./

RUN pnpm install --force --prod=false --no-frozen-lockfile

COPY . .
RUN pnpm build


FROM hub.b1-it.ru/wodby/nginx:1.25-5.33.0

ENV NGINX_SERVER_EXTRA_CONF_FILEPATH=extra.conf
# prevent add header X-FRAME-OPTIONS (https://github.com/wodby/nginx/blob/master/templates/nginx.conf.tmpl#L142)
# ENV NGINX_NO_DEFAULT_HEADERS=true
COPY nginx.conf /etc/nginx/extra.conf
COPY --chown=wodby:wodby --from=builder /usr/src/app/dist /var/www/html
COPY --chown=wodby:wodby --from=builder /usr/src/app/env-config.tpl.js /var/www/html/env-config.tpl.js
ENTRYPOINT ["/bin/bash", "-c", \
            "gotpl '/var/www/html/env-config.tpl.js' > '/var/www/html/env-config.js' \
            && /docker-entrypoint.sh sudo nginx"]

