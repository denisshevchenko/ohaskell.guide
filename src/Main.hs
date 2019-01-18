module Main where

import           CreateEpub
import           CreateHtml
import           CreateHtmlTemplates
import           CreatePdf
import           SingleMarkdown

import           Control.Concurrent.Async (async, wait)
import           Control.Monad            (when)
import           Data.List                (intercalate)
import           System.Environment       (getArgs, withArgs)
import           System.Exit              (exitFailure)

main :: IO ()
main = do
    (pathToSingleMarkdown, chapterPoints, practicePoints) <- createSingleMarkdown

    args <- getArgs
    check args

    buildEpubIfNecessary         args pathToSingleMarkdown
    buildPdfIfNecessary          args pathToSingleMarkdown
    buildPdfPrintableIfNecessary args pathToSingleMarkdown
    buildHtmlIfNecessary         args chapterPoints practicePoints

buildEpubIfNecessary :: [String] -> FilePath -> IO ()
buildEpubIfNecessary args pathToSingleMarkdown =
    when (buildAllOrJust epub args) $ do
        buildingVersion epub
        createEpub pathToSingleMarkdown

buildPdfIfNecessary :: [String] -> FilePath -> IO ()
buildPdfIfNecessary args pathToSingleMarkdown =
    when (buildAllOrJust pdf args) $ do
        -- Самые тяжеловесные операции.
        buildingVersion pdf
        pdfDesktopDone <- async $ createPdfDesktop pathToSingleMarkdown
        pdfMobileDone  <- async $ createPdfMobile pathToSingleMarkdown
        wait pdfDesktopDone
        wait pdfMobileDone

buildPdfPrintableIfNecessary :: [String] -> FilePath -> IO ()
buildPdfPrintableIfNecessary args pathToSingleMarkdown =
    when (buildAllOrJust pdfPrintable args) $ do
        buildingVersion pdfPrintable
        createPdfPrintable pathToSingleMarkdown

buildHtmlIfNecessary :: [String]
                     -> [ChapterPoint]
                     -> [ChapterPoint]
                     -> IO ()
buildHtmlIfNecessary args chapterPoints practicePoints =
    when (buildAllOrJust html args) $ do
        buildingVersion html
        createHtmlTemplates chapterPoints practicePoints
        -- Аргумент rebuild нужен для Hakyll.
        withArgs ["rebuild"] $ createHtml chapterPoints practicePoints

check :: [String] -> IO ()
check args =
    when someInvalidArgs $ do
        putStrLn $ "Usage: ohaskell [" ++ intercalate "|" validArgs ++ "]"
        exitFailure
  where
    someInvalidArgs = not . null $ filter invalid args
    invalid arg     = arg `notElem` validArgs
    validArgs       = [pdf, pdfPrintable, epub, html]

buildAllOrJust :: String -> [String] -> Bool
buildAllOrJust some args = some `elem` args || null args

pdf, pdfPrintable, epub, html :: String
pdf             = "--pdf"
pdfPrintable    = "--pdf-printable"
epub            = "--epub"
html            = "--html"

buildingVersion :: String -> IO ()
buildingVersion ver = putStrLn $ " Build " ++ drop 2 ver ++ " version..."

