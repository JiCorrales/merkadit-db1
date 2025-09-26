import express from 'express';
import morgan from 'morgan';
import "dotenv/config";

const app = express();

app.use(morgan('dev'));
app.use(express.json());

app.get('/', (_req, res) => {
    res.send('Hello from API');
});
app.listen(process.env.PORT, () => {
    console.log("Server running on port " + process.env.PORT);
  // Initialization hooks could go here (e.g. database connection)
});

export default app;
