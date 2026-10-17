--- @diagnostic disable: inject-field

--- @type LDK_Core_Namespace
local ns = select(2, ...)

local L = ns:NewLocale('itIT')
if not L then return end

-- Untranslated keys fall back to enUS.
L['LuaDevKit Code Editor'] = 'Editor di codice LuaDevKit'
L['Wrap Text'] = 'A capo automatico'
L['Wrap Text::Desc'] =
  "Manda a capo le righe lunghe per adattarle alla larghezza dell'editor invece di scorrere in orizzontale."
L['Resize Output'] = 'Ridimensiona output'
L['Resize Output::Desc'] =
  'Trascina per ridimensionare il pannello di output. Usa le frecce per ingrandirlo o ridurlo.'
L['Double-click to maximize'] = 'Doppio clic per ingrandire'
L['Double-click to minimize'] = 'Doppio clic per ridurre'
L['Maximize Output'] = 'Ingrandisci output'
L['Maximize Output::Desc'] = 'Espande il pannello di output alla dimensione massima.'
L['Minimize Output'] = 'Riduci output'
L['Minimize Output::Desc'] = 'Riduce il pannello di output alla dimensione minima.'
L['Theme'] = 'Tema'
L['Theme::Desc'] = "Scegli il tema dell'editor."
L['Font Family'] = 'Carattere'
L['Font Family::Desc'] = "Scegli il carattere usato nell'editor."
L['Font Size'] = 'Dimensione carattere'
L['Font Size::Desc'] = "Scegli la dimensione del carattere dell'editor."
L['Increase Font Size'] = 'Aumenta dimensione carattere'
L['Increase Font Size::Desc'] = "Porta il carattere dell'editor alla dimensione successiva."
L['Decrease Font Size'] = 'Riduci dimensione carattere'
L['Decrease Font Size::Desc'] = "Porta il carattere dell'editor alla dimensione precedente."
L['Command Line'] = 'Riga di comando'
L['Command Line::Desc'] =
  'Esegue una singola riga di Lua e ne mostra il risultato nel pannello di output.'
L['Command Line::HelpTip'] = 'Esegui qui una riga di Lua'
L['Command History'] = 'Cronologia comandi'
L['Command History::Desc'] = 'Scegli un comando precedente per rimetterlo nella riga di comando.'
L['Command History::HelpTip'] = 'Scegli qui un comando recente'
L['No Command History'] = 'Nessuna cronologia comandi'
L['Console Settings'] = 'Impostazioni console'
L['Console Settings::Desc'] =
  'Scegli carattere e dimensione del pannello di output e della riga di comando.'
L['Console Font'] = 'Carattere console'
L['Console Font Size'] = 'Dimensione carattere console'
L['Same as Editor'] = "Come l'editor"
L['Clear Output'] = 'Cancella output'
L['Clear Output::Desc'] = 'Rimuove tutto il testo dal pannello di output.'
L['Editor Helpers'] = "Funzioni di supporto dell'editor"
L['Editor Helpers::Desc'] = "Funzioni integrate per il codice nell'editor e nella riga di comando."
L['Editor Helpers::p'] = 'Stampa nel pannello di output'
L['Editor Helpers::t'] = 'Traccia su /etrace'
L['Editor Helpers::fm'] = 'Formatta un valore su più righe indentate'
L['Editor Helpers::fs'] = 'Formatta un valore su una riga'
L['Editor Helpers::fv'] = 'Mostra chiavi e valori di una tabella come coppie key=value'
L['Editor Helpers::inspect'] = 'Valuta <val> nel Table Inspector di Blizzard'
L['Editor Helpers::help'] = 'Stampa questo elenco'
L['inspect: expected a table, got %s'] = 'inspect: attesa una tabella, ricevuto %s'
L['Editor Helpers::Hint'] = 'Clicca per stampare questo elenco nel pannello di output'
L['Run'] = 'Esegui'
L['Run::Desc'] = "Esegue il codice nell'editor e ne mostra l'output nel pannello di output."
L['Run::Hint'] = "Ctrl+1 per eseguire con il cursore nell'editor"
L['Run::Hint::Mac'] = "Cmd+1 per eseguire con il cursore nell'editor"
L['Run::HelpTip'] = 'Esegui il tuo codice'
L['New Document'] = 'Nuovo documento'
L['New Document::Desc'] = 'Crea un nuovo documento Lua vuoto.'
L['Save Document'] = 'Salva documento'
L['Save Document::Desc'] = 'Salva questo documento.'
L['Save Document::Hint'] = 'Nessuna modifica non salvata'
L['Delete Document'] = 'Elimina documento'
L['Delete Document::Desc'] = 'Elimina questo documento.'
L['Delete "%s"?'] = 'Eliminare "%s"?'
L['Delete'] = 'Elimina'
L['Open Document'] = 'Apri documento'
L['Open Document::Desc'] = 'Passa a un altro documento; le frecce scorrono i documenti.'
L['Open Document::Hint'] = 'Maiusc-clic per rinominare\nAlt-clic per salvare come nuovo documento'
L['Rename Document'] = 'Rinomina documento'
L['Save Document As'] = 'Salva documento con nome'
L['%s Copy'] = '%s (copia)'
L['Untitled'] = 'Senza titolo'
L['Show Toolbar'] = 'Mostra barra degli strumenti'
L['Show Toolbar::Desc'] = "Mostra la barra degli strumenti sopra l'area del codice."
L['Options::HelpTip'] = 'Altre opzioni qui'
L['Save on Run'] = "Salva all'esecuzione"
L['Save on Run::Desc'] = 'Salva il documento ogni volta che lo esegui.'
L['Output Panel'] = 'Pannello di output'
L['Output Panel::Desc'] = 'Mostra il pannello di output sotto il codice o alla sua destra.'
L['Output Panel::Hint::Right'] = 'Clicca per spostarlo a destra'
L['Output Panel::Hint::Bottom'] = 'Clicca per spostarlo in basso'
L['Bottom'] = 'In basso'
L['Right'] = 'A destra'
L['Profile'] = 'Profilo'
L['This'] = 'Questo'
L['Manage Profiles...'] = 'Gestisci profili...'
L['Requires %s'] = 'Richiede %s'
L['Reset Profile::Confirm'] =
  'Ripristinare %s? Tutti i documenti di questo profilo verranno eliminati. Questa operazione non può essere annullata.'
L['Copy From::Confirm'] =
  'Copiare i documenti da %s? Tutti i documenti di questo profilo verranno sostituiti. Questa operazione non può essere annullata.'
L['Save changes to "%s"?'] = 'Salvare le modifiche a "%s"?'
L['Save'] = 'Salva'
L['Cancel'] = 'Annulla'
L['Discard'] = 'Scarta'
L['General'] = 'Generale'
L['Open Editor at Startup'] = "Apri l'editor all'avvio"
L['Open Editor at Startup::Desc'] =
  "Apre l'editor di codice all'accesso o al ricaricamento dell'interfaccia."
L['Escape Key Closes Editor'] = "Il tasto Esc chiude l'editor"
L['Escape Key Closes Editor::Desc'] =
  "Premi Esc per chiudere l'editor di codice. Se la finestra delle impostazioni è aperta, Esc chiude prima quella."
L["Remember Blizzard's Table Inspector Location"] =
  'Ricorda la posizione del Table Inspector di Blizzard'
L["Remember Blizzard's Table Inspector Location::Desc"] =
  "Apre il Table Inspector di inspect() o ti() dove l'hai spostato l'ultima volta, invece che al centro."
L['Available commands:'] = 'Comandi disponibili:'
L['displays the addon info'] = "mostra le informazioni dell'addon"
L['toggles the Code Editor'] = "mostra o nasconde l'editor di codice"
L['toggles the settings window'] = 'mostra o nasconde la finestra delle impostazioni'
