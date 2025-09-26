import 'dotenv/config';
import express from 'express';

const app = express();
const port = process.env.PORT;

app.use(express.json());

app.use('/api', (req, res) => {
    res.send('Hello from API');
});


export default app;
