.pragma library

var quotes = {
    stoic: [
        { text: "We suffer more often in imagination than in reality.", author: "Seneca" },
        { text: "Waste no more time arguing about what a good person should be. Be one.", author: "Marcus Aurelius" },
        { text: "No person has the power to have everything they want, but it is in their power not to want what they do not have.", author: "Seneca" },
        { text: "It is not that we have a short time to live, but that we waste a lot of it.", author: "Seneca" },
        { text: "First say to yourself what you would be, and then do what you have to do.", author: "Epictetus" },
        { text: "You have power over your mind, not outside events. Realize this, and you will find strength.", author: "Marcus Aurelius" },
        { text: "Difficulty shows what people are made of.", author: "Epictetus" },
        { text: "He who fears death will never do anything worthy of a person who is alive.", author: "Seneca" },
        { text: "Dwell on the beauty of life. Watch the stars, and see yourself running with them.", author: "Marcus Aurelius" },
        { text: "Begin at once to live, and count each separate day as a separate life.", author: "Seneca" }
    ],
    builder: [
        { text: "Simplicity is the ultimate sophistication.", author: "Leonardo da Vinci" },
        { text: "What I cannot create, I do not understand.", author: "Richard Feynman" },
        { text: "Details make perfection, and perfection is not a detail.", author: "Leonardo da Vinci" },
        { text: "Real artists ship.", author: "Steve Jobs" },
        { text: "I have no special talent. I am only passionately curious.", author: "Albert Einstein" },
        { text: "Make things as simple as possible, but not simpler.", author: "Albert Einstein" },
        { text: "The best way to predict the future is to invent it.", author: "Alan Kay" },
        { text: "Nature does not hurry, yet everything is accomplished.", author: "Lao Tzu" },
        { text: "Genius is one percent inspiration and ninety-nine percent perspiration.", author: "Thomas Edison" },
        { text: "Everything around you that you call life was made up by people no smarter than you.", author: "Steve Jobs" }
    ],
    cosmic: [
        { text: "The cosmos is within us. We are made of star-stuff.", author: "Carl Sagan" },
        { text: "Time is a created thing. To say I do not have time is to say I do not want to.", author: "Lao Tzu" },
        { text: "For small creatures such as we, the vastness is bearable only through love.", author: "Carl Sagan" },
        { text: "Let everything happen to you, beauty and terror. Just keep going. No feeling is final.", author: "Rainer Maria Rilke" },
        { text: "The present is the only thing of which a person can be deprived.", author: "Marcus Aurelius" },
        { text: "The future enters into us, in order to transform itself in us, long before it happens.", author: "Rainer Maria Rilke" },
        { text: "Time expands, then contracts, all in tune with the stirrings of the heart.", author: "Haruki Murakami" },
        { text: "We are an impossibility in an impossible universe.", author: "Ray Bradbury" },
        { text: "Look deep into nature, and then you will understand everything better.", author: "Albert Einstein" },
        { text: "The nitrogen in our DNA and the iron in our blood were made in collapsing stars.", author: "Carl Sagan" }
    ],
    intensity: [
        { text: "Action is the foundational key to all success.", author: "Pablo Picasso" },
        { text: "Energy and persistence conquer all things.", author: "Benjamin Franklin" },
        { text: "Do not count the days, make the days count.", author: "Muhammad Ali" },
        { text: "Great acts are made up of small deeds.", author: "Lao Tzu" },
        { text: "You must do the thing you think you cannot do.", author: "Eleanor Roosevelt" },
        { text: "It always seems impossible until it is done.", author: "Nelson Mandela" },
        { text: "Concentrate all your thoughts upon the work in hand. The sun's rays do not burn until focused.", author: "Alexander Graham Bell" },
        { text: "A year from now you may wish you had started today.", author: "Karen Lamb" },
        { text: "Discipline is the bridge between goals and accomplishment.", author: "Jim Rohn" },
        { text: "The secret of getting ahead is getting started.", author: "Mark Twain" }
    ],
    adaptiveBeginning: [
        { text: "A journey of a thousand miles begins with a single step.", author: "Lao Tzu" },
        { text: "The beginning is the most important part of the work.", author: "Plato" },
        { text: "Do not wait. The time will never be just right.", author: "Napoleon Hill" },
        { text: "Courage is the first of human qualities because it guarantees all others.", author: "Winston Churchill" }
    ],
    adaptiveMiddle: [
        { text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein" },
        { text: "Perseverance is failing nineteen times and succeeding the twentieth.", author: "Julie Andrews" },
        { text: "Rivers know this: there is no hurry. We shall get there some day.", author: "A. A. Milne" },
        { text: "Patience and persistence have a magical effect before which difficulties disappear.", author: "John Quincy Adams" }
    ],
    adaptiveSprint: [
        { text: "The final sprint demands the calmest mind.", author: "Epictetus" },
        { text: "Finish each day and be done with it. You have done what you could.", author: "Ralph Waldo Emerson" },
        { text: "Stay hungry, stay foolish.", author: "Whole Earth Catalog" },
        { text: "Great things are done by a series of small things brought together.", author: "Vincent van Gogh" }
    ],
    adaptiveReached: [
        { text: "Every summit is within reach if you keep climbing.", author: "Unknown" },
        { text: "To know how to wait is the great secret of success.", author: "Joseph de Maistre" },
        { text: "Well done is better than well said.", author: "Benjamin Franklin" },
        { text: "What we achieve inwardly will change outer reality.", author: "Plutarch" }
    ]
};

function getCuratedQuote(archetype, progressRatio) {
    var pool = quotes.builder;
    var arch = (archetype || "adaptive").toLowerCase();

    if (arch === "stoic") {
        pool = quotes.stoic;
    } else if (arch === "cosmic") {
        pool = quotes.cosmic;
    } else if (arch === "intensity") {
        pool = quotes.intensity;
    } else if (arch === "builder") {
        pool = quotes.builder;
    } else {
        var ratio = Number(progressRatio) || 0.0;
        if (ratio >= 1.0) {
            pool = quotes.adaptiveReached;
        } else if (ratio >= 0.75) {
            pool = quotes.adaptiveSprint;
        } else if (ratio >= 0.25) {
            pool = quotes.adaptiveMiddle;
        } else {
            pool = quotes.adaptiveBeginning;
        }
    }

    var idx = Math.floor(Math.random() * pool.length);
    return pool[idx];
}
