

window.onload = function () {
	var headlines = 0, 
		tickers = 0,
		nested = 0,
		trailing = 0,
		ticker = null;

	function addHeadline() {
		document.querySelector('#headlines').innerHTML += "<li>Headline " + ++headlines + "</li>";
	}

	function addTrailing() {
		document.querySelector('#trailing').innerHTML += "<li>Trailing " + ++trailing + "</li>";
	}
	
	function addTicker() {
		document.querySelector('#ticker').innerHTML += "<li>Ticker " + ++tickers + "</li>";
		if (tickers > 200) {
			clearInterval(ticker);
		}
	}

	function addNested() {
		var nest = document.querySelector('#nested');
		var node = document.createElement('div');
		++nested;
		var html = '<h3 id="nested' + nested + '">Nested ' + nested + '</h3><ul>';
		for (var i = 0; i < 4; i++) {
			html += '<li>Item ' + i + '</li>';
		}
		html += '</ul>';
		node.innerHTML = html;
		nest.appendChild(node);
	}

	ticker = setInterval(addTicker, 1000);

	setTimeout(function () {
		for (var i = 1; i <= 10; i++) {
			addHeadline()
			addNested()
		}
	}, 1000);

	for (var i = 1; i <= 5; i++) {
		setTimeout(addTrailing, 500 * i);
	}

}

