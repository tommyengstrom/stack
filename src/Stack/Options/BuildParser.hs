{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

module Stack.Options.BuildParser where

import qualified Data.Map as Map
import           Options.Applicative
import           Options.Applicative.Args
import           Options.Applicative.Builder.Extra
import           Stack.Options.Completion
import           Stack.Options.PackageParser (readFlag)
import           Stack.Prelude
import           Stack.Types.Config
import           Stack.Types.Version

-- | Parser for CLI-only build arguments
buildOptsParser :: BuildCommand
                -> Parser BuildOptsCLI
buildOptsParser cmd =
    BuildOptsCLI <$>
    targetsParser <*>
    switch
        (long "dry-run" <>
         help "Don't build anything, just prepare to") <*>
    ((\v x y z ->
           concat [v, x, y, z]) <$>
     flag
         []
         ["-Wall", "-Werror"]
         (long "pedantic" <>
          help "Turn on -Wall and -Werror") <*>
     flag
         []
         ["-O0"]
         (long "fast" <>
          help "Turn off optimizations (-O0)") <*>
     flag
         []
         ["-Wwarn"]
         (long "sloppy" <>
          help "Turn off -Werror") <*>
     many
         (textOption
              (long "ghc-options" <>
               metavar "OPTIONS" <>
               completer ghcOptsCompleter <>
               help "Additional options passed to GHC"))) <*>
    flagsParser <*>
    (flag'
         BSOnlyDependencies
         (long "dependencies-only" <>
          help "A synonym for --only-dependencies") <|>
     flag'
         BSOnlySnapshot
         (long "only-snapshot" <>
          help
              "Only build packages for the snapshot database, not the local database") <|>
     flag'
         BSOnlyDependencies
         (long "only-dependencies" <>
          help
              "Only build packages that are dependencies of targets on the command line") <|>
     pure BSAll) <*>
    (flag'
         FileWatch
         (long "file-watch" <>
          help
              "Watch for changes in local files and automatically rebuild. Ignores files in VCS boring/ignore file") <|>
     flag'
         FileWatchPoll
         (long "file-watch-poll" <>
          help
              "Like --file-watch, but polling the filesystem instead of using events") <|>
     pure NoFileWatch) <*>
    many (cmdOption
             (long "exec" <>
              metavar "CMD [ARGS]" <>
              help "Command and arguments to run after a successful build")) <*>
    switch
        (long "only-configure" <>
         help
             "Only perform the configure step, not any builds. Intended for tool usage, may break when used on multiple packages at once!") <*>
    pure cmd <*>
    switch
        (long "initial-build-steps" <>
         help "For target packages, only run initial build steps needed for GHCi" <>
         internal)

targetsParser :: Parser [Text]
targetsParser =
    many
        (textArgument
             (metavar "TARGET" <>
              completer targetCompleter <>
              help ("If none specified, use all local packages. " <>
                    "See https://docs.haskellstack.org/en/v" <>
                    versionString stackMinorVersion <>
                    "/build_command/#target-syntax for details.")))

flagsParser :: Parser (Map.Map ApplyCLIFlag (Map.Map FlagName Bool))
flagsParser =
     Map.unionsWith Map.union <$>
     many
         (option
              readFlag
              (long "flag" <>
               completer flagCompleter <>
               metavar "PACKAGE:[-]FLAG" <>
               help
                   ("Override flags set in stack.yaml " <>
                    "(applies to local packages and extra-deps)")))
