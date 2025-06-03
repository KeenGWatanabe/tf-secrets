1. Sign up for a Snyk account - https://snyk.io/
2. Once logged in, you can see an overview of linked projects e.g. Github repositories that you import in the Dashboard
3. Get your AP token by going to the bottom left (your name) > account settings > click to show key under Auth Token > copy token > create a Github Actions Secret in your Github repository called "SNYK_TOKEN"
$ npm install -g snyk
$ snyk --version
$ snyk auth
![auth snynk using github](/images/snykAuth.png)
![auth in terminal](/images/snykAuth1.png)

Ref: https://github.com/KeenGWatanabe/snyk-scan

Include your AWS SECRET KEY and AWS ACCESS KEY in Github Actions Secret.
Take a look at the sample .github/workflows/package-scan.yml file on a simple workflow to test IAC, Code and Open Source plugins + npm audit.

![Snyk scan result](/images/secretsSnykScan.png)