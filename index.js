require('dotenv').config();
const { Builder, By } = require('selenium-webdriver');
const { Options } = require('selenium-webdriver/chrome');
const { createTransport } = require('nodemailer');

(async function() {
	let driver;

	try {
		//Browser Setup
		let builder = new Builder().forBrowser('chrome');
		let options = new Options();
		options.headless(); // run headless Chrome
		options.excludeSwitches([ 'enable-logging' ]); // disable 'DevTools listening on...'
		options.addArguments([ '--no-sandbox' ]); // not an advised flag but eliminates "DevToolsActivePort file doesn't exist" error.
		driver = await builder.setChromeOptions(options).build();

		// Go to filtered craigslist page
		await driver.get(process.env.FILTERED_CRAIGSLIST_LISTINGS_URL);
		const divs = await driver.findElements(By.className('result-title hdrlnk'));
		const hrefs = await Promise.all(divs.map((div) => div.getAttribute('href')));

		let html = '<p>Here are some recent rental listings that meet your criteria:</p>';
		hrefs.forEach((href) => (html += `<p>${href}</p>`));

		const transporter = createTransport({
			service: 'gmail',
			auth: {
				user: process.env.GMAIL_USERNAME,
				pass: process.env.GMAIL_PASSWORD
			}
		});

		const mailOptions = {
			from: process.env.FROM_ADDRESS,
			to: process.env.TO_ADDRESS,
			subject: 'Recent Craigslist Rental Listings',
			html
		};

		await transporter.sendMail(mailOptions);
	} catch (e) {
		console.log(e);
	} finally {
		if (driver) {
			await driver.close(); // helps chromedriver shut down cleanly and delete the "scoped_dir" temp directories that eventually fill up the harddrive.
			await driver.quit();
		}
	}
})();
