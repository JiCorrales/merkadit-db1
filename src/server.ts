import app from "./app";

app.listen(process.env.PORT, async () => {
    console.log(`Server running on port ${process.env.PORT}`);

    // Aqui podriamos logica de inicializacion, como conectar a la base de datos
    // await initializeDatabaseConnection();
});