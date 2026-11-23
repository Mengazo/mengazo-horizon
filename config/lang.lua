-- Texts shown to the player. Pick the language with LANGUAGE in config.lua, or edit the texts here.
-- {distance} is replaced by the distance, such as "193 m" or "1.3 km".
return {
    ['en'] = {
        KEY_LABEL = 'Map markers on the horizon', -- name of the key in Settings > Key Bindings > FiveM
        DEFAULT_LABEL = 'Marked place', -- name used when a blip has no name in the game
        MARKERS = 'Markers',
        NO_MARKERS = 'No markers nearby',
        AIM_HINT = 'Aim at a marker to see its details',
        DISTANCE = '{distance} away',
        CURRENT_DESTINATION = 'Current destination · {distance}',
        VIEW_ON_MAP = 'View on map',
        SET_DESTINATION = 'Set destination',
        REMOVE_DESTINATION = 'Remove destination',
        DECIMAL_SEPARATOR = '.',
    },

    ['pt-BR'] = {
        KEY_LABEL = 'Marcadores no horizonte',
        DEFAULT_LABEL = 'Local marcado',
        MARKERS = 'Marcadores',
        NO_MARKERS = 'Nenhum marcador por perto',
        AIM_HINT = 'Mire em um marcador para ver os detalhes',
        DISTANCE = 'A {distance}',
        CURRENT_DESTINATION = 'Destino atual · {distance}',
        VIEW_ON_MAP = 'Ver no mapa',
        SET_DESTINATION = 'Definir destino',
        REMOVE_DESTINATION = 'Remover destino',
        DECIMAL_SEPARATOR = ',',
    },
}
