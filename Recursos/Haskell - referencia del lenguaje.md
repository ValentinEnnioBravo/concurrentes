# Haskell: referencia del lenguaje

Sintaxis y funciones de consulta. La teoría (pureza, Functor/Applicative/Monad, IO, STM) está en [3. Haskell](../Clases/3.%20Haskell.md).

## Tipos

Conocer el tipo de un valor en GHCi:

```haskell
Prelude> :t 'a'
'a' :: Char
Prelude> :t 4 + 3
4 + 3 :: Num a => a
```

Declarar el tipo de una función:

```haskell
succ :: Int -> Int
succ a = a + 1

Prelude> :t head
head :: [a] -> a

Prelude> :t tail
tail :: [a] -> [a]
```

En estos casos `a` es un **tipo genérico**, pero el valor es **consistente**: si entra una lista de `Int`, `head` devuelve un `Int`.

## Typeclasses

Una typeclass es una interfaz que define un comportamiento. Si un tipo es parte de una typeclass, soporta e implementa ese comportamiento (como las interfaces de Java, pero implementando el comportamiento, no solo definiendo el contrato).

```haskell
Prelude> :t (+)
(+) :: Num a => a -> a -> a
```

A la derecha del `=>` se lee como cualquier función: toma dos valores de tipo `a` y devuelve otro de tipo `a`. A la izquierda se indica que `a` tiene que ser miembro de la typeclass `Num`. Eso se llama **class constraint**.

```haskell
Prelude> :t (<=)
(<=) :: Ord a => a -> a -> Bool
```

`Ord` define la interfaz de ordenamiento (`<`, `>`, `<=`, `>=`, entre otras): cualquier tipo que necesite comparar elementos tiene que ser miembro de `Ord`. `Show` define `show :: a -> String`, que es lo que usa `print` para convertir un valor a texto.

## Sintaxis básica

| Elemento | Haskell |
|---|---|
| Comentario | `-- un comentario` / `{- un comentario multilínea -}` |
| Strings | `"uNa CadEna"` |
| Caracteres | `'a'` |
| Símbolos/Átomos | NA |
| Booleanos | `True` `False` |
| Set | NA |
| Lista | `[]` / `[1,2]` |
| Patrones de listas | `(cabeza:cola)` / `(cabeza:segundo:cola)` |
| Tuplas | `(comp1, comp2)` |
| Data/Functores | `Constructor comp1 comp2` |
| Bloques sin parámetros | NA |
| Bloques / Exp. lambda (un parámetro) | `(\x -> algo con x)` |
| Bloques / Exp. lambda (más de un parámetro) | `(\x y -> algo con x e y)` |
| Variable anónima | `_` |

## Operadores lógicos y matemáticos

| Operación | Haskell |
|---|---|
| Equivalencia | `==` |
| Identidad | NA |
| ~ Equivalencia | `/=` |
| Comparación de orden | `> >= < <=` |
| Entre valores | NA |
| Disyunción (O lógico) | `||` / `or` |
| Conjunción (Y lógico) | `&&` / `and` |
| Negación | `not unBool` |
| Operadores aritméticos | `+ - * /` |
| División entera | `div dividendo divisor` |
| Resto | `mod dividendo divisor` |
| Valor absoluto | `abs unNro` |
| Exponenciación | `base ^ exponente` |
| Raíz cuadrada | `sqrt unNro` |
| Máximo entre dos números | `max unNro otroNro` |
| Mínimo entre dos números | `min unNro otroNro` |
| Par | `even unNro` |
| Impar | `odd unNro` |

## Operaciones simples sin efecto sobre listas

| Operación | Haskell |
|---|---|
| Longitud | `length :: [a] -> Int` ** / `genericLength :: Num n => [a] -> n` * |
| Si está vacía | `null :: [a] -> Bool` ** |
| Preceder (nueva cabeza) | `(:) :: a -> [a] -> [a]` |
| Concatenación | `(++) :: [a] -> [a] -> [a]` |
| Unión | `union :: Eq a => [a] -> [a] -> [a]` * |
| Intersección | `intersect :: Eq a => [a] -> [a] -> [a]` * |
| Acceso por índice | `(!!) :: [a] -> Int -> a` (base 0) |
| Pertenencia | `elem :: Eq a => a -> [a] -> Bool` ** |
| Máximo | `maximum :: Ord a => [a] -> a` ** |
| Mínimo | `minimum :: Ord a => [a] -> a` ** |
| Sumatoria | `sum :: Num a => [a] -> a` ** |
| Aplanar | `concat :: [[a]] -> [a]` ** |
| Primeros n elementos | `take :: Int -> [a] -> [a]` |
| Sin los primeros n elementos | `drop :: Int -> [a] -> [a]` |
| Primer elemento | `head :: [a] -> a` |
| Último elemento | `last :: [a] -> a` |
| Cola | `tail :: [a] -> [a]` |
| Segmento inicial (sin el último) | `init :: [a] -> [a]` |
| Apareo de listas | `zip :: [a] -> [b] -> [(a, b)]` |
| Elemento random | NA |
| Sin repetidos | NA |
| Lista en el orden inverso | `reverse :: [a] -> [a]` |

## Operaciones de orden superior sobre listas

| Operación | Haskell |
|---|---|
| Sumatoria según transformación | NA |
| Filtrar | `filter :: (a->Bool) -> [a] -> [a]` |
| Transformar | `map :: (a->b) -> [a] -> [b]` |
| Todos cumplen (true para lista vacía) | `all :: (a->Bool) -> [a] -> Bool` |
| Alguno cumple (false para lista vacía) | `any :: (a->Bool) -> [a] -> Bool` |
| Transformar y aplanar | `concatMap :: (a->[b]) -> [a] -> [b]` |
| Reducir/plegar a izquierda | `foldl :: (a->b->a) -> a -> [b] -> a` / `foldl1 :: (a->a->a) -> [a] -> a` |
| Reducir/plegar a derecha | `foldr :: (b->a->a) -> a -> [b] -> a` / `foldr1 :: (a->a->a) -> [a] -> a` |
| Apareo con transformación | `zipWith :: (a->b->c) -> [a] -> [b] -> [c]` |
| Primer elemento que cumple condición | `find :: (a->Bool) -> [a] -> a` * ** |
| Cantidad de elementos que cumplen condición | NA |
| Obtener colección ordenada | `sort :: Ord a => [a] -> [a]` * ** |
| Máximo según criterio | NA |
| Mínimo según criterio | NA |

## Funciones de orden superior sin listas

| Operación | Haskell |
|---|---|
| Aplica una función con un valor (menor precedencia que la aplicación normal) | `($) :: (a->b) -> a -> b` |
| Compone dos funciones | `(.) :: (b->c) -> (a->b) -> (a->c)` |
| Invierte la aplicación de los parámetros de una función | `flip :: (a->b->c) -> b -> a -> c` |

## Funciones de generación de listas

| Operación | Haskell |
|---|---|
| Lista que repite infinitamente al elemento dado | `repeat :: a -> [a]` |
| Lista infinita `[x, f x, f (f x), ...]` | `iterate :: (a->a) -> a -> [a]` |
| Repite n veces al elemento dado | `replicate :: Int -> a -> [a]` |
| Lista infinita `xs ++ xs ++ xs ++ ...` | `cycle :: [a] -> [a]` |

**Notas de las tablas**
- **NA**: "No Aplica". No existe o no se recomienda su uso.
- **\*** Declarada en `Data.List`.
- **\*\*** El tipo presentado es una versión simplificada del tipo real.
- **\*\*\*** En algunos cursos, en vez de `Int` o `(Num n => n)` puede aparecer `Number`.

## Definir tipos con `data`

`data` permite definir un tipo propio enumerando sus constructores:

```haskell
data Booleano = Verdadero | Falso

data Lista a = Nil | Cons a (Lista a)     -- vacía, o un elemento seguido de otra lista
```

Un valor de `Lista` no se puede imprimir: falta que el tipo pertenezca a `Show`. Se soluciona derivándola:

```haskell
data Lista a = Nil | Cons a (Lista a) deriving Show
```

lo cual a su vez exige `Show` sobre `a` (`instance Show a => Show (Lista a)`).

Además, un literal como `1` es polimórfico (`Num a => a`, no un tipo concreto), así que `Cons 1 Nil` tiene tipo `Num a => Lista a`: una `Lista a` para cualquier `a` numérico, todavía sin decidir cuál. Para imprimirlo, ese `a` tiene que resolverse a un tipo concreto (GHCi lo hace por *defaulting*, normalmente `Integer`; en código compilado conviene anotar, por ejemplo `Lista Int`).

## List, Maybe y Either

**Lista**

```haskell
data List a = Nil | Cons a (List a)

laLista123 = Cons 1 (Cons 2 (Cons 3 Nil))   -- en sintaxis nativa: [1, 2, 3]

hermanos "Jon" = ["Robb", "Sansa", "Arya", "Bran"]   -- varios resultados posibles
```

**Maybe** (en otros lenguajes, *Option*): un valor que puede estar o no.

```haskell
data Maybe a = Nothing | Just a

findUser :: Int -> Maybe User
findUser 1 = Just (User "Alice")
findUser 2 = Just (User "Bob")
findUser _ = Nothing            -- si no existe
```

**Either** (en otros lenguajes, *Result*): uno de dos tipos posibles, nunca ambos. Por convención `Right` es el éxito ("correcto") y `Left` el error.

```haskell
data Either a b = Left a | Right b

parseInt :: String -> Either String Int
parseInt "42"  = Right 42
parseInt "abc" = Left "No es un número válido"
```

A diferencia de las excepciones, que son "invisibles" en la firma y pueden aparecer de sorpresa, `Either` obliga a declarar y manejar el error explícitamente.

## IO: componer acciones

```haskell
import System.IO

hPutStr  :: Handle -> String -> IO ()
hGetLine :: Handle -> IO String

main :: IO ()
main = do
  hPutStr stdout "Hola mundo!"
```

- `>>` encadena dos acciones descartando el resultado de la primera:

  ```haskell
  main = (hPutStr stdout "Hola mundo!") >> (hPutStr stdout "Mi segunda linea")
  ```

- `>>=` pasa el resultado de una acción a la siguiente:

  ```haskell
  main = getLine >>= (\a -> hPutStr stdout a)
  ```

- La notación `do` escribe lo mismo como un bloque secuencial:

  ```haskell
  main = do
      a <- getLine
      hPutStr stdout a
  ```

- `return :: a -> IO a` mete un valor en la caja `IO`: no corta la función como en otros lenguajes, es una función más.

  ```haskell
  prepend :: Handle -> IO String
  prepend h = do
      s <- hGetLine h
      hPutStr h "Linea de prepend antes de la linea leida del handle."
      return s
  ```

Más información sobre IO: <https://www.haskell.org/tutorial/io.html>
