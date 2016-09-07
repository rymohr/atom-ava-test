# https://github.com/avajs/atom-ava/issues/3
# https://discuss.atom.io/t/how-to-execute-node-js-child-process-from-package/4880/12
#
# https://github.com/thedaniel/terminal-panel
# https://atom.io/packages/terminal-status
# https://github.com/rburns/ansi-to-html
#
# https://github.com/axross/tap-notify
# https://github.com/substack/faucet
# https://github.com/joeybaker/tap-simple
# https://github.com/toolness/tap-prettify

fs = require 'fs'
Path = require 'path'
{BufferedProcess} = require 'atom'

isSourceFile = (path) ->
  path.endsWith('.js') && !isTestFile(path)

isTestFile = (path) ->
  path.endsWith('.test.js')

getTestPath = (path) ->
  if path.endsWith('test.js')
    path
  else
    path.replace(/js$/, 'test.js')

getDir = (path) ->
  Path.dirname(path)

getBasename = (path) ->
  Path.basename(path)

isExistingFile = (path) ->
  fs.existsSync(path)

module.exports = AtomAvaTest =
  panel: null
  element: null
  process: null

  activate: (state) ->
    code = document.createElement('code')

    pre = document.createElement('pre')
    pre.appendChild(code)

    @element = el = document.createElement('div')
    @element.classList.add('ava-test')
    @element.addEventListener('click', -> el.classList.remove('active'))
    @element.appendChild(pre)

    atom.workspace.onDidStopChangingActivePaneItem((editor) ->
      # won't be a TextEditor instance for find and replace, settings, etc
      return unless editor && editor.getPath

      # may be a new file
      return unless path = editor.getPath()

      if isSourceFile(path)
        testPath = getTestPath(path)

        if isExistingFile(testPath)
          atom.workspace.open(testPath, {
            split: 'right',
            activatePane: false,
            activateItem: true,
          })
    )

    atom.workspace.observeTextEditors((editor) ->
      editor.onDidSave((event) ->
        { path } = event

        if isSourceFile(path) || isTestFile(path)
          testPath = getTestPath(path)

          return unless isExistingFile(testPath)

          AtomAvaTest.process?.kill()

          output = ''

          append = (line) ->
            code.innerHTML = (output += line)

          testDir = getDir(testPath)
          testFile = getBasename(testPath)
          command = '/usr/local/bin/ava'
          args = ['--require', 'babel-register', '--tap', testFile, '|', 'faucet']
          options = {cwd: testDir}
          stdout = stderr = append
          exit = (code) -> el.dataset.exitCode = code

          append("TEST #{testPath}\n")

          el.dataset.exitCode = undefined
          el.classList.add('active')

          AtomAvaTest.process = new BufferedProcess({command, args, options, stdout, stderr, exit})
      )
    )

    @panel = atom.workspace.addBottomPanel({
      item: @element
    })

  deactivate: ->
    @panel.destroy()
    @process?.kill()
