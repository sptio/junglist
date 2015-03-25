# Junglist

Opinionated LiveScript library for hauling ass and making websites, using [Slm](https://github.com/slm-lang/slm) and [Stylus](http://learnboost.github.io/stylus/).

## Install

```
npm install junglist
```

## Use

This will serve "pages/index.slm".

```livescript
require! express
require! junglist

server = express!
server.get "/", junglist.page "index"
server.listen 5000
```

## Functions

### junglist.page

Render a .slm template from the "pages" directory.

```livescript
server.get "/", junglist.page "index"
```

### junglist.style

Render a .styl sheet from the "styles" directory.

```livescript
server.get "/theme", junglist.style "theme"
```

### junglist.script

Render a .ls script from the "scripts" directory.

```livescript
server.get "/main", junglist.script "main"
```

### junglist.app

Serve a [browserify](http://browserify.org)'d script from the "apps" directory. [Watchify](https://github.com/substack/watchify) and [debowerify](https://github.com/eugeneware/debowerify) are baked in.

```livescript
server.get "/app", junglist.app "index"
```

### junglist.reloader

Simple auto-reload capability.

```livescript
server.use "/reload", junglist.reloader "/reload"
```

Use with .app:

```livescript
reloader = junglist.reloader "/reload"
server.use "/reload", reloader
server.use "/app", junglist.app "my-app"
  update: reloader.reload
```

## Slm Extensions

### markdown:

slm-markdown is included.

### style:

Stylus in Slm.

```slim
  head
    style:
      a
        color blue
        &:hover
          text-decoration underline

```

### script:

LiveScript in Slm.

```slim
  body
    script:
      for x in [1 to 10]
        console.log "hello #x!"
```

### include:

Stylus, LiveScript, or raw content.

```slim
  head
    include:
      some-snippet.html
      style theme
      script main
```

## Stylus Extensions

### embed-font

Embed a font as a data: URI from the "fonts" directory. .woff is assumed.

```stylus
  @font-face
    font-family icons
    src url(embed-font("icons")) format("woff")
```

## todo

- tests
- less/more opinions
- styles/shared (global includes)