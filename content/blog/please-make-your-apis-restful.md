---
title: "Please Make Your APIs Restful"
date: 2021-11-16T22:33:15-05:00
draft: false
description: And have proper docs also.
---

Have you ever been working on something but it doesn't work properly
and you don't know why? This is exactly what I thought when I was working
on [Circleload](https://github.com/TorchedSammy/Circleload) yesterday.

It's a tool that downloads osu! beatmaps from unofficial mirrors. One of them was
[Kitsu](https://kitsu.moe) (not the anime list) that looked really simple.
Except when it returned status code 200 for a beatmap I *know* doesn't exist.

Turns out that this API, when getting a beatmap, returns an object like this:  
```json
{
	"code": 404,
	"message": "Not found"
}
```
when a beatmap isn't found. You know what else is great? None of these keys are sent
on a successful request.

Thought that was all? When ratelimited while trying to download, Kitsu still sends
you a nice 200 status code but sends a body of text. What if you're not ratelimited?
Normal binary data stream.

Please document your APIs and make then RESTful so I don't cry while trying to
figure out what's wrong.

