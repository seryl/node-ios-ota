ios-ota
=======

A node-based iOS over-the-air service.

## REST Interface

<table>
  <tr>
    <th>Command</th><th>Method</th><th>Url</th><th>Example</th>
  </tr>
  <tr>
    <td>version</td>
    <td>GET</td>
    <td>/</td>
    <td>curl -sL localhost:3000/</td>
  </tr>
  <tr>
    <td>list users</td>
    <td>GET</td>
    <td>/users/</td>
    <td>curl -sL localhost:3000/users</td>
  </tr>
  <tr>
    <td>create user</td>
    <td>POST</td>
    <td>/users/<code>user</code></td>
    <td>curl -sL -H "Content-Type: application/json" -X POST localhost:3000/users/<code>user</code> -d '{"username":"admin","secret":"admin"}'</td>
  </tr>
  <tr>
    <td>create application</td>
    <td>/<code>user</code>/<code>application</code></td>
    <td>curl -sL -H "Content-Type: application/json" -X PUT localhost:3000/<code>user</code>/<code>application</code> -d '{"username":"admin","secret":"admin"}'</td>
  </tr>
  <tr>
    <td>status (all)</td>
    <td>/status</td>
    <td>curl -sL http://localhost:8080/status</td>
  </tr>
  <tr>
    <td>status (specific)</td>
    <td>/status/<code>system</code></td>
    <td>curl -sL http://localhost:8080/status/<code>6cbb78b2925a</code></td>
  </tr>
</table>

## Code Status

[![build status](https://secure.travis-ci.org/seryl/node-ios-ota.png)](http://travis-ci.org/seryl/node-ios-ota)
