const html = `<html>
  <head>
    <title>LaFleet - Shape Upload</title>
  </head>
  <body>
  <h1>LaFleet - Shape Upload</h1>

    <p>Draw the shape with <a href="https://observablehq.com/@claude-ducharme/h3-drawing-on-mapbox">h3-drawing-on-mapbox</a> and Select the polygon to display.</p>
    <p>Copy/paste the polygon json into the box of <a href=https://observablehq.com/@claude-ducharme/prepare-shapes>prepare-shapes</a>. Overwrite it's name, select its type, and status.</p>
    <p>Copy/paste the shape into the form below and press ENTER to upload to finally save in the backend.</p>
    
    <form action="/upload-shape" method="post">
      <textarea id="shapeJson" name="shapeJson" rows="20" cols="100" style="resize: true, monospace: true"></textarea>
      <input type="submit" value="Submit">
    </form>


  </body>
</html>`;

exports.handler = function(event, context) {
    const response = {
        statusCode: 200,
        headers: {
            "Content-Type": "text/html"
        },
        body: html,
        isBase64Encoded: false
    };
    //return response;
    context.succeed(response);
}
