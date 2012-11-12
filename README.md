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
    <td>PUT</td>
    <td>/<code>user</code>/<code>application</code></td>
    <td>curl -sL -H "Content-Type: application/json" -X PUT localhost:3000/<code>user</code>/<code>application</code> -d '{"username":"admin","secret":"admin"}'</td>
  </tr>
  <tr>
    <td>create a branch</td>
    <td>PUT</td>
    <td>/<code>user</code>/<code>application</code>/branches/<code>branch</code></td>
    <td>curl -sL -H "Content-Type: application/json" -X PUT localhost:3000/<code>user</code>/<code>application</code>/branches/<code>branch</code> -d '{"username":"admin","secret":"admin"}'</td>
  </tr>
  <tr>
    <td>create a tag</td>
    <td>PUT</td>
    <td>/<code>user</code>/<code>application</code>/tags/<code>tag</code></code></td>
    <td>curl -sL -H "Content-Type: application/json" -X PUT localhost:3000/<code>user</code>/<code>application</code>/tags/<code>tag</code> -d '{"username":"admin","secret":"admin"}'</td>
  </tr>
  <tr>
    <td>upload files for a branch/tag</td>
    <td>PUT</td>
    <td>
      /<code>user</code>/<code>application</code>/branches/<code>branch</code>
      <br />OR<br />
      /<code>user</code>/<code>application</code>/tags/<code>tag</code>
    </td>
    <td>curl -sL -H "Content-Type: application/json" -X PUT localhost:3000/<code>user</code>/<code>application</code> -d '{"username":"admin","secret":"admin"}'</td>
  </tr>
</table>

## Code Status

[![build status](https://secure.travis-ci.org/seryl/node-ios-ota.png)](http://travis-ci.org/seryl/node-ios-ota)
