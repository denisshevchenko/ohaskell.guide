# Новый тип

Помимо `data` существует ещё одно ключевое слово, предназначенное для определения нового типа. Оно так и называется &mdash; `newtype`. Эти слова похожи друг на друга &laquo;в одну сторону&raquo;: вы можете поставить `data` на место `newtype`, но не наоборот.

## Различия

Тип, определяемый с помощью слова `newtype`, обязан иметь один и только один конструктор значения. Мы можем написать так:
 
```haskell
newtype IPAddress = IP String
```

А вот так не можем:

```haskell
newtype IPAddress = IP String | Localhost
```

Компилятор заупрямится:

```bash
A newtype must have exactly one constructor,
  but ‘IPAddress’ has two
In the newtype declaration for ‘IPAddress’
```

Кроме того, в таком типе должно быть одно и лишь одно поле. То есть можно так:

```haskell
newtype IPAddress = IP String
```

Или же так, с меткой:

```haskell
newtype IPAddress = IP { value :: String }
```

А вот два или более полей запихнуть не удастся:

```haskell
newtype EndPoint = EndPoint String Int
```

Компилятор вновь обратит наше внимание на проблему:

```bash
The constructor of a newtype must have exactly one field
  but ‘EndPoint’ has two
In the definition of data constructor ‘EndPoint’
In the newtype declaration for ‘EndPoint’
```

Более того, нульарный конструктор тоже не подойдёт:

```haskell
newtype HardDay = Monday
```

И вновь ошибка:

```bash
The constructor of a newtype must have exactly one field
  but ‘Monday’ has none
```

## Зачем он нужен?

В самом деле, зачем нам нужно такое хозяйство? Это нельзя, то нельзя. Какой смысл?

Смысл в оптимизации. Обратите внимание на модель `newtype`:

```haskell
newtype IPAddress = IP           String

новый   название    конструктор  Поле
тип                 значения
```

Фактически, `newtype` берёт одно-единственное значение некоторого существующего типа и всего лишь оборачивает его в свой конструктор. Именно поэтому тип, введённый с помощью `newtype`, не относится к АТД, и с точки зрения компилятора он является лишь переименованием типа (англ. type renaming). Это делает такой тип более простым и эффективным с точки зрения представления в памяти, нежели тип, определяемый с `data`.

Когда мы пишем так:

```haskell
data IPAddress = IP String
```

мы говорим компилятору: &laquo;`IPAddress` &mdash; это абсолютно новый и самобытный тип, которого никогда не было ранее&raquo;. А когда пишем так:

```haskell
newtype IPAddress = IP String
```

мы говорим: &laquo;`IPAddress` &mdash; это всего лишь обёртка для значения уже существующего типа `String`&raquo;.

## type vs newtype

Внимательный читатель спросит, в чём же фундаментальное отличие типов, вводимых с помощью `newtype`, от типов, вводимых с помощью `type`? Там синоним, тут &mdash; обёртка. Отличие вот в чём.

Когда мы пишем так:

```haskell
type String = [Char]
```

мы объявляем: &laquo;Тип `String` &mdash; это эквивалентная замена типу `[Char]`&raquo;. И поэтому везде, где в коде стоит `[Char]`, мы можем поставить `String`, и везде, где стоит `String`, мы можем поставить `[Char]`. Например, если функция объявлена так:

```haskell
replace :: String
        -> String
        -> String
        -> String
```

мы можем спокойно переписать объявление:

```haskell
replace :: [Char]
        -> [Char]
        -> [Char]
        -> [Char]
```

и ничего не изменится.

Когда же мы пишем так:

```haskell
newtype MyInt = MyInt Int
```

мы объявляем: &laquo;Тип `MyInt` &mdash; это новый тип, представление которого такое же, как у типа `Int`&raquo;. Мы не можем просто взять и поставить `MyInt` на место `Int`, потому что эти типы равны лишь с точки зрения представления в памяти, с точки зрения системы типов они абсолютно различны.

А зачем же нам нужно это? Для простоты и надёжности кода. Допустим, есть такая функция:

```haskell
getBuildsInfo :: String -> Int -> BuildsInfo
getBuildsInfo projectName limit = ...
```

Эта функция запрашивает у CI-сервиса (через REST API) информацию о сборках проекта. Из определения мы видим, что первым аргументом выступает имя проекта, а вторым &mdash; количество сборок. Однако в месте применения функции это может быть не столь очевидным:

```haskell
  let info = getBuildsInfo "ohaskell.guide" 4
```

Что такое первая строка? Что такое второе число? Неясно, нужно глядеть в определение, ведь даже объявление не расскажет нам правду:

```haskell
getBuildsInfo :: String  -> Int    -> BuildsInfo

                 что за     что за
                 строка?    число?
```

Вот тут нам и помогают наши типы, ведь стандартные `String` и `Int` сами по себе не несут никакой полезной информации о своём содержимом. Конечно, мы могли бы обойтись и без типов, просто введя промежуточные выражения:

```haskell
  let project = "ohaskell.guide"
      limit   = 4
      info    = getBuildsInfo project limit
```

Однако программист может этого и не сделать, и тогда мы получим &laquo;магические значения&raquo;, смысл которых нам неизвестен. Куда лучше ввести собственные типы:

```haskell
newtype Project = Project String
newtype Limit = Limit Int

getBuildsInfo :: Project -> Limit  -> BuildsInfo

                 уже не     уже не
                 просто     просто
                 строка     число
```

Это заставит нас писать явно:

```haskell
  let info = getBuildsInfo (Project "ohaskell.guide")
                           (Limit 4)
```

Теперь, даже без промежуточных выражений, смысл строки и числа вполне очевиден. Это важный принцип в Haskell: безликие типы наподобие `String` или `Int` заменять на типы, имеющие конкретный смысл для нас.

Кроме того, `newtype`-типы помогают нам не допускать глупых ошибок. Например, есть другая функция:

```haskell
getArtifacts :: String -> Int -> Int -> [Project]
getArtifacts projectName limit offset = ...
```

Мало того, что перед нами вновь безликие `Int`, так их ещё и два. И вот какая нелепая ошибка может нас поджидать:

```haskell
  let project = "ohaskell.guide"
      limit   = 4
      offset  = 1
      info    = getArtifacts project offset limit
```

Заметили? Мы случайно перепутали аргументы местами, поставив `offset` на место `limit`. Работа функции при этом нарушится, однако компилятор останется нем как рыба, ведь с точки зрения системы типов ошибки не произошло: и там `Int`, и тут `Int`. Синонимы для `Int` также не помогли бы. Однако если у нас будут `newtype`-типы:

```haskell
newtype Limit = Limit Int
newtype Offset = Offset Int
```

тогда подобная ошибка не пройдёт незамеченной:

```haskell
  let project = "ohaskell.guide"
      limit   = Limit 4
      offset  = Offset 1
      info    = getArtifacts project offset limit
```

Типы аргументов теперь разные, а значит, путаница между ними гарантированно прервёт компиляцию.

Вот такие они, `newtype`-типы. В последующих главах мы увидим ещё большую мощь системы типов Haskell.

