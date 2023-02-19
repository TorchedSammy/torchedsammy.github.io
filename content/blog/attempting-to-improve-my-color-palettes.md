---
title: "Attempting to Improve My Colorscheme"
date: 2023-02-10T11:11:47-04:00
draft: true
---

I've made a few custom colorschemes before to fit in with
my Linux ricing and have colors to my liking. I've also read a few
other blog posts about color spaces and things like that.
I made my colorschemes by just picking some colors in a RGB
color picker and using what seems fit to me, but that does have some issues.

![My Colorscheme, Stardew Night](https://safe.kashima.moe/cffhaiz2p1i9.png)

If you look at this image here, you might notice that pink is the
brightest color here, quite a bit more than the others.

In the LAB color space, it looks like this:
![](https://safe.kashima.moe/ys470zn2ms7p.png)
Notice the lightness value here.

If we compare another color, like maybe red or purple, this is the result:
![My red in the LAB color space](https://safe.kashima.moe/db3megu8y6dq.png)

![My purple in the LAB color space](https://safe.kashima.moe/fbgx7z8cq956.png)

As you can notice, the lightness values for all 3 of these are different,
with the difference between pink and red being 11.

Let's see what kind of color we get if we use this LAB color picker to
get a pink based on the lightness of red.

![](https://safe.kashima.moe/gaqel6gmn3q8.png)
That's.. terrible, and it was the best fit.

Let's try a different color as a base? Yellow maybe, since it's hard to get a
good yellow at low lightness.

![](https://safe.kashima.moe/e0elqy6nptc5.png)

Terrible again.

Instead, I'll go with a different color space, specifically OKLCH.
![](https://safe.kashima.moe/m6l5g4gkorai.png)

In this case I had to edit some of the values shown here (chroma and hue)
so that (almost) every color would fit within the standard *gamut*. You see
those "Show P3" and "Show Rec2020" switches. Those are switches to see the
selected color in a wider gamut, which basically just means there are more
colors those monitors can show for more vibrance. So now, let's try
reconstructing our colors based on this pink.

That gives us this:
![](https://safe.kashima.moe/5n7n2kvyruy1.png)
![](https://safe.kashima.moe/bvssl6cyh76z.png)

While it definitely does look close in lightness, the vibrance is also
gone, and this colorscheme looks a bit dull to me.

Yet another strategy I had was to take yellow as the base, but only
change green. I also realized that I could also change the chroma value,
and for a *personal* colorscheme, the lightness values don't need to
match exactly and would still look good enough. So I took the other
colors and changed them around to fit close enough in lightness
while looking nice enough for me.

So with all that, we have the final version:
![](https://safe.kashima.moe/7ex22ozv67va.png)
![](https://safe.kashima.moe/x8bw1mvf2hjl.png)

I still don't really know a whole log about color spaces and whatever
about accessible palettes, but this is good enough for me. I didn't want
the color scheme to look too different, and the purple is exactly what
I wanted.

I may do this for another one of my color schemes in the future so stay tuned!
