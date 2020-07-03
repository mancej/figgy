OKTA Guide that actually works (their docs are sketch AF):

https://saml-doc.okta.com/SAML_Docs/How-to-Configure-SAML-2.0-for-Amazon-Web-Service.html?baseAdminUrl=https://dev-216899-admin.okta.com&app=amazon_aws&instanceId=0oaapi6m5hJsYZghz4x6#A-step1

When you run `terraform apply`, if you are configuring SSO, figgy is going to look for a file named 
`metadata.xml` in here. This should match your IDP's SAML metadata document.