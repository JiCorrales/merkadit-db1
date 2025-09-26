import 'dotenv/config';
import express from 'express';

const app = express();
const port = process.env.PORT;

app.use(express.json());

app.use('/api', (req, res) => {
    res.send('Hello from API');
});
app.listen(port, () => {
    console.log('Server ready at http://localhost:' + port);
});

export default app;
