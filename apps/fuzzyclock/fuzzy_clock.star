load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("encoding/json.star", "json")

DEFAULT_LOCATION = {
    "lat": 40.7,
    "lng": -74.0,
    "locality": "Brooklyn",
}
DEFAULT_TIMEZONE = "US/Eastern"

numbersPerLang = {
    "en-US": {
        1: "ONE",
        2: "TWO",
        3: "THREE",
        4: "FOUR",
        5: "FIVE",
        6: "SIX",
        7: "SEVEN",
        8: "EIGTH",
        9: "NINE",
        10: "TEN",
        11: "ELEVEN",
        12: "TWELVE",
        15: "QUARTER",
        20: "TWENTY",
        25: "TWENTY-FIVE",
        30: "HALF",
    },
    "nl-BE": {
        1: "ÉÉN",
        2: "TWEE",
        3: "DRIE",
        4: "VIER",
        5: "VIJF",
        6: "ZES",
        7: "ZEVEN",
        8: "ACHT",
        9: "NEGEN",
        10: "TIEN",
        11: "ELF",
        12: "TWAALF",
        15: "KWART",
        20: "TWINTIG",
        25: "VIJFENTWINTIG",
        30: "HALF",
    },
}
numbersPerLang["en-GB"] = numbersPerLang["en-US"]

wordsPerLang = {
    "en-US": {
        "hour": "O'CLOCK",
        "to": "TILL",
        "past": "PAST",
    },
    "en-GB": {
        "hour": "O'CLOCK",
        "to": "TO",
        "past": "PAST",
    },
    "nl-BE": {
        "hour": "UUR",
        "to": "VOOR",
        "past": "OVER",
    },
}

def round(minutes):
    """Returns:
        minutes: rounded to the nearest 5.
        up: if we rounded up or down.
    """
    rounded = (minutes + 2) % 60 // 5 * 5
    up = False

    if rounded > 30:
        rounded = 60 - rounded
        up = True
    elif minutes > 30 and rounded == 0:
        up = True

    return rounded, up

def fuzzy_time(hours, minutes, language):
    numbers = numbersPerLang[language]
    words = wordsPerLang[language]

    glue = words["past"]
    rounded, up = round(minutes)

    if up:
        hours += 1
        glue =  words["to"]

    # Handle 24 hour time.
    if hours > 12:
        hours -= 12

    # Handle midnight.
    if hours == 0:
        hours = 12

    if rounded == 0:
        return [numbers[hours], words["hour"]]
    
    # Handle special case for Dutch
    if rounded == 30 and language == "nl-BE":
        hours = hours + 1 if hours < 12 else hours - 11
        return [numbers[rounded], numbers[hours]]

    return [numbers[rounded], glue, numbers[hours]]

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)
    language = config.get("language") or "en-US"

    fuzzed = fuzzy_time(now.hour, now.minute, language)

    # Add some left padding for ~style~.
    texts = [render.Text(" " * i + s) for i, s in enumerate(fuzzed)]

    return render.Root(
        child = render.Padding(
            pad = (4,4,0,0),
            child = render.Column(
                children = texts,
            ),
        ),
    )

def get_schema():
    languageOptions = [
        schema.Option(
            display = "American English",
            value = "en-US",
        ),
        schema.Option(
            display = "British English",
            value = "en-GB",
        ),
        schema.Option(
            display = "Dutch (Belgisch)",
            value = "nl-BE",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                icon = "place",
                desc = "Location for which to display time",
            ),
            schema.Dropdown(
                id = "language",
                name = "language",
                icon = "language",
                desc = "Language",
                default = languageOptions[0].value,
                options = languageOptions,
            ),
        ],
    )
