require('dotenv').config();
const express = require('express');

const router = require('./app/router');
const {cleaner} = require('./app/middlewares');

const app = express();

const expressSwagger = require('express-swagger-generator')(app);

const port = process.env.PORT || 5000;


app.use(cleaner);

app.use('/v1', router);

let options = {
    swaggerDefinition: {
        info: {
            description: 'A booking REST API',
            title: 'Oparc',
            version: '1.0.0',
        },
        host: `localhost:${port}`,
        basePath: '/v1',
        produces: [
            "application/json"
        ],
        schemes: ['http', 'https']
    },
    basedir: __dirname, 
    files: ['./app/**/*.js'] 
};
expressSwagger(options);


app.listen(port, () => {
    console.log(`Server started on http://localhost:${port}`);
});