{-# LANGUAGE OverloadedStrings #-}

module CreateEpub (
    createEpub
) where

import           System.Process     (callCommand)
import           System.Directory   (getHomeDirectory)

import           CreateEpubCss

createEpub :: FilePath -> IO ()
createEpub pathToSingleMarkdown = do
    createEpubCss pathToCss
    callCommand $ concat [ "pandoc -S -o "
                         , out
                         , " --toc-depth=2"
                         , " --epub-stylesheet="
                         , pathToCss
                         , " --epub-embed-font="
                         , mainFont
                         , " --epub-embed-font="
                         , codeFontNormal
                         , " --epub-embed-font="
                         , codeFontBold
                         , " --epub-cover-image="
                         , cover
                         , " "
                         , title
                         , " "
                         , pathToSingleMarkdown
                         ]
  where
    out       = "epub/ohaskell.epub"
    pathToCss = "epub/EPUB.css"
    title     = "epub/EPUBTitle.txt"
    cover     = "epub/cover.png"

    -- Пути актуальны для Linux. Подразумевается, что данные шрифты уже установлены.
    mainFont        = "$HOME/.local/share/fonts/PTS55F.ttf"
    codeFontNormal  = "/usr/share/fonts/truetype/ubuntu-font-family/UbuntuMono-R.ttf"
    codeFontBold    = "/usr/share/fonts/truetype/ubuntu-font-family/UbuntuMono-B.ttf"
