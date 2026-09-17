type Universo = [Personaje]
type Gema = Personaje -> Personaje
type Habilidad = String

data Guantelete = UnGuantelete {
    material :: String,
    gemas :: [Gema]
}

data Personaje = UnPersonaje {
    edad :: Float,
    energia :: Float,
    habilidades :: [Habilidad],
    nombre :: String,
    planeta :: String
} deriving (Show, Eq)

estaCompleto :: Guantelete -> Bool
estaCompleto = ((==6).length.gemas)

chasquido :: Guantelete -> Universo -> Universo
chasquido guantelete universo | estaCompleto guantelete && material guantelete == "uru" = take (round (fromIntegral (length universo) / 2)) universo
                              | otherwise = universo

aptoPendex :: Universo -> Bool
aptoPendex = any (\p -> edad p < 45)

energiaTotal :: Universo -> Float
energiaTotal = sum.(map(\p -> energia p)).(filter (\p -> (length.habilidades) p > 1))

usarContra :: Personaje -> Guantelete -> Personaje -> Personaje
usarContra personaje guantelete enemigo = enemigo

gemaMente :: Float -> Gema
gemaMente valor persona = reducirEnergia valor persona

gemaAlma :: Habilidad -> Gema
gemaAlma habilidad = (eliminarHabilidad habilidad).(reducirEnergia 10)

gemaPoder :: Gema
gemaPoder personaje | cantidadHabilidades personaje <= 2 = reducirEnergia 10 personaje {habilidades = []}
                    | otherwise = reducirEnergia 10 personaje

gemaEspacio :: String -> Gema
gemaEspacio planeta = (transportar planeta).(reducirEnergia 20)

gemaTiempo :: Gema
gemaTiempo personaje = reducirEnergia 50 personaje {edad = ((max 18).(/2).edad) personaje}

gemaLoca :: Gema -> Gema
gemaLoca gema = gema . gema

guanteleteGoma = UnGuantelete "goma" [gemaTiempo, gemaAlma "usar Mjolnir", gemaLoca (gemaAlma "programacion en Haskell")]

utilizar :: [Gema] -> Personaje -> Personaje
utilizar gemas personaje = foldl (\p gema -> gema p) personaje gemas

gemaMasPoderosa :: Guantelete -> Personaje -> Gema
gemaMasPoderosa guantelete personaje = laMasPoderosa (gemas guantelete) personaje

perdidaDeEnergia :: Gema -> Personaje -> Float
perdidaDeEnergia gema personaje = abs((energia (gema personaje)) - energia personaje)

laMasPoderosa :: [Gema] -> Personaje -> Gema
laMasPoderosa (x:[]) _ = x
laMasPoderosa (x:y:ys) personaje | perdidaDeEnergia x personaje > perdidaDeEnergia y personaje = laMasPoderosa (x:ys) personaje
                                 | otherwise = laMasPoderosa (y:ys) personaje



-- EFECTO DE LADO Y JUSTIFICACION TEORICA 

-- AUXILIARES 
reducirEnergia :: Float -> Personaje -> Personaje
reducirEnergia valor persona = persona {energia = energia persona - valor}

eliminarHabilidad :: Habilidad -> Personaje -> Personaje
eliminarHabilidad habilidad persona = persona {habilidades = filter (\h -> h /= habilidad) (habilidades persona)}

cantidadHabilidades :: Personaje -> Int
cantidadHabilidades = length.habilidades

transportar :: String -> Personaje -> Personaje 
transportar planeta personaje = personaje {planeta = planeta}