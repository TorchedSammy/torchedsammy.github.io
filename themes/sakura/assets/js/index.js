var params = require('@params')

var darkClass = 'fa-solid fa-moon'
var lightClass = 'fa-solid fa-sun'

var toggle = document.getElementById('theme-switch')
toggle.onclick = function(e) {
	if (toggle.className === darkClass) {
		setTheme('light', true)
	} else if (toggle.className === lightClass) {
		setTheme('dark', true)
	}
	e.preventDefault()
}

function setTheme(mode, setTheme) {
	var link = document.createElement('link')
	link.rel = 'stylesheet'
	link.type = 'text/css'

	if (setTheme) { localStorage.setItem('site-theme', mode) }
	if (mode === 'dark') {
		toggle.className = darkClass
		link.href = params.dark
	} else if (mode === 'light') {
		toggle.className = lightClass
		link.href = params.light
	}
	document.head.appendChild(link)
}


var savedTheme = localStorage.getItem('site-theme') || 'dark'
setTheme(savedTheme)

window.addEventListener('storage', (event) => {
	if (event.key === 'site-theme') {
		setTheme(event.newValue)
	}
});
