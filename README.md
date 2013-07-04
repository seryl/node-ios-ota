ios-ota [![build status](https://secure.travis-ci.org/seryl/node-ios-ota.png?branch=master)](https://travis-ci.org/seryl/node-ios-ota)
=======

A node-based iOS over-the-air service with a full REST interface.

## REST Interface

Get the version
```
curl -sL localhost:3000
```

Get the list of users
```
curl -sL localhost:3000/users
```

Create a user
```
curl -sL -H "Content-Type: application/json" -X POST localhost:3000/users/zoidberg -d '
{
  "username": "admin",
  "secret": "admin"
}'
```

Create an application
```
curl -sL -H "Content-Type: application/json" -X PUT localhost:3000/zoidberg/brainslugs -d '
{
  "username": "admin",
  "secret": "admin"
}'
```

Creating a branch
```
curl -sL -H "Content-Type: application/json" -X PUT localhost:3000/zoidberg/brainslugs/branches/master
{
  "username": "admin",
  "secret": "admin"
}'
```

Creating a tag
```
curl -sL -H "Content-Type: application/json" -X PUT localhost:3000/zoidberg/brainslugs/tags/1.0
{
  "username": "admin",
  "secret": "admin"
}'
```

Upload files to a branch
```
curl -sL -H "Content-Type: application/json" -X PUT -T @filename.ipa \
localhost:3000/zoidberg/brainslugs/branches/master -d '
{
  "username": "admin",
  "secret": "admin"
}'
```

Upload files to a tag
```
curl -sL -H "Content-Type: application/json" -X PUT -T @filename.ipa \
localhost:3000/zoidberg/brainslugs/tags/1.0 -d '
{
  "username": "admin",
  "secret": "admin"
}'
```
