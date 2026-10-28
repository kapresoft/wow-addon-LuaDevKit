--- @diagnostic disable: inject-field

--- @type LDK_Core_Namespace
local ns = select(2, ...)

local L = ns:NewLocale('frFR')
if not L then return end

-- Untranslated keys fall back to enUS.
L['LuaDevKit Code Editor'] = 'Éditeur de code LuaDevKit'
L['Wrap Text'] = 'Retour à la ligne'
L['Wrap Text::Desc'] =
  "Renvoie les longues lignes à la ligne pour tenir dans la largeur de l'éditeur au lieu de défiler horizontalement."
L['Resize Output'] = 'Redimensionner la sortie'
L['Resize Output::Desc'] =
  "Faites glisser pour redimensionner le panneau de sortie. Utilisez les flèches pour l'agrandir ou le réduire."
L['Double-click to maximize'] = 'Double-clic pour agrandir'
L['Double-click to minimize'] = 'Double-clic pour réduire'
L['Maximize Output'] = 'Agrandir la sortie'
L['Maximize Output::Desc'] = 'Agrandit le panneau de sortie à sa taille maximale.'
L['Minimize Output'] = 'Réduire la sortie'
L['Minimize Output::Desc'] = 'Réduit le panneau de sortie à sa taille minimale.'
L['Theme'] = 'Thème'
L['Theme::Desc'] = "Choisir le thème de l'éditeur."
L['Font Family'] = 'Police'
L['Font Family::Desc'] = "Choisir la police utilisée dans l'éditeur."
L['Font Size'] = 'Taille de police'
L['Font Size::Desc'] = "Choisir la taille de police de l'éditeur."
L['Increase Font Size'] = 'Augmenter la taille de police'
L['Increase Font Size::Desc'] = "Passe la police de l'éditeur à la taille suivante."
L['Decrease Font Size'] = 'Diminuer la taille de police'
L['Decrease Font Size::Desc'] = "Passe la police de l'éditeur à la taille précédente."
L['Command Line'] = 'Ligne de commande'
L['Command Line::Desc'] =
  'Exécute une seule ligne de Lua et affiche son résultat dans le panneau de sortie.'
L['Command Line::HelpTip'] = 'Exécutez une ligne de Lua ici'
L['Command History'] = 'Historique des commandes'
L['Command History::Desc'] =
  'Choisir une commande précédente pour la remettre sur la ligne de commande.'
L['Command History::HelpTip'] = 'Choisissez une commande récente ici'
L['No Command History'] = 'Aucun historique de commandes'
L['Console Settings'] = 'Paramètres de la console'
L['Console Settings::Desc'] =
  'Choisir la police et la taille du panneau de sortie et de la ligne de commande.'
L['Console Font'] = 'Police de la console'
L['Console Font Size'] = 'Taille de police de la console'
L['Same as Editor'] = "Comme l'éditeur"
L['Clear Output'] = 'Effacer la sortie'
L['Clear Output::Desc'] = 'Supprime tout le texte du panneau de sortie.'
L['Editor Helpers'] = "Fonctions d'aide de l'éditeur"
L['Editor Helpers::Desc'] =
  "Fonctions intégrées pour le code dans l'éditeur et sur la ligne de commande."
L['Editor Helpers::p'] = 'Afficher dans le panneau de sortie'
L['Editor Helpers::t'] = 'Tracer vers /etrace'
L['Editor Helpers::fm'] = 'Formater une valeur sur plusieurs lignes indentées'
L['Editor Helpers::fs'] = 'Formater une valeur sur une seule ligne'
L['Editor Helpers::fv'] = "Afficher les clés et valeurs d'une table sous forme de paires key=value"
L['Editor Helpers::inspect'] = 'Évaluer <val> dans le Table Inspector de Blizzard'
L['Editor Helpers::help'] = 'Afficher cette liste'
L['inspect: expected a table, got %s'] = 'inspect : table attendue, %s reçu'
L['Editor Helpers::Hint'] = 'Cliquez pour afficher cette liste dans le panneau de sortie'
L['Run'] = 'Exécuter'
L['Run::Desc'] = "Exécute le code de l'éditeur et affiche sa sortie dans le panneau de sortie."
L['Run::Hint'] = "Ctrl+1 pour exécuter quand le curseur est dans l'éditeur"
L['Run::Hint::Mac'] = "Cmd+1 pour exécuter quand le curseur est dans l'éditeur"
L['Run::HelpTip'] = 'Exécutez votre code'
L['New Document'] = 'Nouveau document'
L['New Document::Desc'] = 'Crée un nouveau document Lua vide.'
L['Save Document'] = 'Enregistrer le document'
L['Save Document::Desc'] = 'Enregistre ce document.'
L['Save Document::Hint'] = 'Aucune modification non enregistrée'
L['Delete Document'] = 'Supprimer le document'
L['Delete Document::Desc'] = 'Supprime ce document.'
L['Delete "%s"?'] = 'Supprimer « %s » ?'
L['Delete'] = 'Supprimer'
L['Open Document'] = 'Ouvrir un document'
L['Open Document::Desc'] = 'Passe à un autre document ; les flèches parcourent les documents.'
L['Open Document::Hint'] =
  'Maj-clic pour renommer\nAlt-clic pour enregistrer comme nouveau document'
L['Rename Document'] = 'Renommer le document'
L['Save Document As'] = 'Enregistrer le document sous'
L['%s Copy'] = 'Copie de %s'
L['Untitled'] = 'Sans titre'
L['Show Toolbar'] = "Afficher la barre d'outils"
L['Show Toolbar::Desc'] = "Affiche la barre d'outils au-dessus de la zone de code."
L['Options::HelpTip'] = "Plus d'options ici"
L['Skip Tour'] = 'Passer la visite'
L['Save on Run'] = "Enregistrer à l'exécution"
L['Save on Run::Desc'] = 'Enregistre le document à chaque exécution.'
L['Output Panel'] = 'Panneau de sortie'
L['Output Panel::Desc'] = 'Affiche le panneau de sortie sous le code ou à sa droite.'
L['Output Panel::Hint::Right'] = 'Cliquez pour le déplacer à droite'
L['Output Panel::Hint::Bottom'] = 'Cliquez pour le déplacer en bas'
L['Bottom'] = 'En bas'
L['Right'] = 'À droite'
L['Profile'] = 'Profil'
L['This'] = 'Ce'
L['Manage Profiles...'] = 'Gérer les profils...'
L['Requires %s'] = 'Nécessite %s'
L['Reset Profile::Confirm'] =
  'Réinitialiser %s ? Tous les documents de ce profil seront supprimés. Cette action est irréversible.'
L['Copy From::Confirm'] =
  'Copier les documents de %s ? Tous les documents de ce profil seront remplacés. Cette action est irréversible.'
L['Save changes to "%s"?'] = 'Enregistrer les modifications de « %s » ?'
L['Save'] = 'Enregistrer'
L['Cancel'] = 'Annuler'
L['Discard'] = 'Ignorer'
L['General'] = 'Général'
L['Open Editor at Startup'] = "Ouvrir l'éditeur au démarrage"
L['Open Editor at Startup::Desc'] =
  "Ouvre l'éditeur de code à la connexion ou au rechargement de l'interface."
L['Escape Key Closes Editor'] = "La touche Échap ferme l'éditeur"
L['Escape Key Closes Editor::Desc'] =
  "Appuyez sur Échap pour fermer l'éditeur de code. Si la fenêtre des paramètres est ouverte, Échap la ferme d'abord."
L["Remember Blizzard's Table Inspector Location"] =
  'Mémoriser la position du Table Inspector de Blizzard'
L["Remember Blizzard's Table Inspector Location::Desc"] =
  "Ouvre le Table Inspector de inspect() ou ti() là où vous l'avez déplacé en dernier, au lieu du centre."
L['Available commands:'] = 'Commandes disponibles :'
L['displays the addon info'] = "affiche les informations de l'addon"
L['toggles the Code Editor'] = "affiche ou masque l'éditeur de code"
L['toggles the settings window'] = 'affiche ou masque la fenêtre des paramètres'
