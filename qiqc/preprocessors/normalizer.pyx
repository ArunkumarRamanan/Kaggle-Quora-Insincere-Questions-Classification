# cython: language_level=3
import re

import numpy as np
cimport numpy as np
from multiprocessing import Pool


cdef class StringReplacer:
    cpdef public dict rule
    cpdef list keys
    cpdef list values
    cpdef int n_rules

    def __init__(self, dict rule):
        self.rule = rule
        self.keys = list(rule.keys())
        self.values = list(rule.values())
        self.n_rules = len(rule)

    def __call__(self, str x):
        cdef int i
        for i in range(self.n_rules):
            if self.keys[i] in x:
                x = x.replace(self.keys[i], self.values[i])
        return x

    def __getstate__(self):
        return (self.rule, self.keys, self.values, self.n_rules)

    def __setstate__(self, state):
        self.rule, self.keys, self.values, self.n_rules = state


cdef class RegExpReplacer:
    cdef dict rule
    cdef list keys
    cdef list values
    cdef regexp
    cdef int n_rules

    def __init__(self, dict rule):
        self.rule = rule
        self.keys = list(rule.keys())
        self.values = list(rule.values())
        self.regexp = re.compile('(%s)' % '|'.join(self.keys))
        self.n_rules = len(rule)

    @property
    def rule(self):
        return self.rule

    def __call__(self, str x):
        def replace(match):
            x = match.group(0)
            if x in self.rule:
                return self.rule[x]
            else:
                for i in range(self.n_rules):
                    x = re.sub(self.keys[i], self.values[i], x)
                return x
        return self.regexp.sub(replace, x)


cpdef str cylower(str x):
    return x.lower()


cpdef list cysplit(str x):
    return x.split()


cdef class PunctSpacer(StringReplacer):

    def __init__(self, edge_only=False):
        puncts = [',', '.', '"', ':', ')', '(', '-', '!', '?', '|', ';', "'", '$', '&', '/', '[', ']', '>', '%', '=', '#', '*', '+', '\\', '•',  '~', '@', '£', '·', '_', '{', '}', '©', '^', '®', '`',  '<', '→', '°', '€', '™', '›',  '♥', '←', '×', '§', '″', '′', 'Â', '█', '½', 'à', '…', '“', '★', '”', '–', '●', 'â', '►', '−', '¢', '²', '¬', '░', '¶', '↑', '±', '¿', '▾', '═', '¦', '║', '―', '¥', '▓', '—', '‹', '─', '▒', '：', '¼', '⊕', '▼', '▪', '†', '■', '’', '▀', '¨', '▄', '♫', '☆', 'é', '¯', '♦', '¤', '▲', 'è', '¸', '¾', 'Ã', '⋅', '‘', '∞', '∙', '）', '↓', '、', '│', '（', '»', '，', '♪', '╩', '╚', '³', '・', '╦', '╣', '╔', '╗', '▬', '❤', 'ï', 'Ø', '¹', '≤', '‡', '√', ]  # NOQA
        if edge_only:
            rule = {
                **dict([(f' {p}', f' {p} ') for p in puncts]),
                **dict([(f'{p} ', f' {p} ') for p in puncts]),
            }
        else:
            rule = dict([(p, f' {p} ') for p in puncts])
        super().__init__(rule)


cdef class NumberReplacer(RegExpReplacer):

    def __init__(self, with_underscore=False):
        prefix, suffix = '', ''
        if with_underscore:
            prefix += ' __'
            suffix = '__ '
        rule = {
            '[0-9]{5,}': f'{prefix}#####{suffix}',
            '[0-9]{4}': f'{prefix}####{suffix}',
            '[0-9]{3}': f'{prefix}###{suffix}',
            '[0-9]{2}': f'{prefix}##{suffix}',
        }
        super().__init__(rule)


cdef class KerasFilterReplacer(StringReplacer):

    def __init__(self):
        filters = '!"#$%&()*+,-./:;<=>?@[\\]^_`{|}~\t\n'
        rule = dict([(f, ' ') for f in filters])
        super().__init__(rule)


cdef class MisspellReplacer(StringReplacer):

    def __init__(self):
        rule = {
            "ain't": "is not",
            "aren't": "are not",
            "can't": "cannot",
            "'cause": "because",
            "could've": "could have",
            "couldn't": "could not",
            "didn't": "did not",
            "doesn't": "does not",
            "don't": "do not",
            "hadn't": "had not",
            "hasn't": "has not",
            "haven't": "have not",
            "he'd": "he would",
            "he'll": "he will",
            "he's": "he is",
            "how'd'y": "how do you",
            "how'd": "how did",
            "how'll": "how will",
            "how's": "how is",
            "i'd've": "i would have",
            "i'd": "i would",
            "i'll've": "i will have",
            "i'll": "i will",
            "i'm": "i am",
            "i've": "i have",
            "isn't": "is not",
            "it'd've": "it would have",
            "it'd": "it would",
            "it'll've": "it will have",
            "it'll": "it will",
            "it's": "it is",
            "let's": "let us",
            "ma'am": "madam",
            "mayn't": "may not",
            "might've": "might have",
            "mightn't've": "might not have",
            "mightn't": "might not",
            "must've": "must have",
            "mustn't've": "must not have",
            "mustn't": "must not",
            "needn't've": "need not have",
            "needn't": "need not",
            "o'clock": "of the clock",
            "oughtn't've": "ought not have",
            "oughtn't": "ought not",
            "shan't've": "shall not have",
            "shan't": "shall not",
            "sha'n't": "shall not",
            "she'd've": "she would have",
            "she'd": "she would",
            "she'll've": "she will have",
            "she'll": "she will",
            "she's": "she is",
            "should've": "should have",
            "shouldn't've": "should not have",
            "shouldn't": "should not",
            "so've": "so have",
            "so's": "so as",
            "this's": "this is",
            "that'd've": "that would have",
            "that'd": "that would",
            "that's": "that is",
            "there'd've": "there would have",
            "there'd": "there would",
            "there's": "there is",
            "here's": "here is",
            "they'd've": "they would have",
            "they'd": "they would",
            "they'll've": "they will have",
            "they'll": "they will",
            "they're": "they are",
            "they've": "they have",
            "to've": "to have",
            "wasn't": "was not",
            "we'd've": "we would have",
            "we'd": "we would",
            "we'll've": "we will have",
            "we'll": "we will",
            "we're": "we are",
            "we've": "we have",
            "weren't": "were not",
            "what'll've": "what will have",
            "what'll": "what will",
            "what're": "what are",
            "what's": "what is",
            "what've": "what have",
            "when's": "when is",
            "when've": "when have",
            "where'd": "where did",
            "where's": "where is",
            "where've": "where have",
            "who'll've": "who will have",
            "who'll": "who will",
            "who's": "who is",
            "who've": "who have",
            "why's": "why is",
            "why've": "why have",
            "will've": "will have",
            "won't've": "will not have",
            "won't": "will not",
            "would've": "would have",
            "wouldn't've": "would not have",
            "wouldn't": "would not",
            "y'all'd've": "you all would have",
            "y'all'd": "you all would",
            "y'all're": "you all are",
            "y'all've": "you all have",
            "y'all": "you all",
            "you'd've": "you would have",
            "you'd": "you would",
            "you'll've": "you will have",
            "you'll": "you will",
            "you're": "you are",
            "you've": "you have",
            "colour": "color",
            "centre": "center",
            "favourite": "favorite",
            "travelling": "traveling",
            "counselling": "counseling",
            "theatre": "theater",
            "cancelled": "canceled",
            "labour": "labor",
            "organisation": "organization",
            "wwii": "world war 2",
            "citicise": "criticize",
            "youtu ": "youtube ",
            "qoura": "quora",
            "sallary": "salary",
            "whta": "what",
            "narcisist": "narcissist",
            "howdo": "how do",
            "whatare": "what are",
            "howcan": "how can",
            "howmuch": "how much",
            "howmany": "how many",
            "whydo": "why do",
            "doi": "do i",
            "thebest": "the best",
            "howdoes": "how does",
            "mastrubation": "masturbation",
            "mastrubate": "masturbate",
            "mastrubating": "masturbating",
            "pennis": "penis",
            "etherium": "ethereum",
            "narcissit": "narcissist",
            "bigdata": "big data",
            "2k17": "2017",
            "2k18": "2018",
            "qouta": "quota",
            "exboyfriend": "ex boyfriend",
            "airhostess": "air hostess",
            "whst": "what",
            "watsapp": "whatsapp",
            "demonitisation": "demonetization",
            "demonitization": "demonetization",
            "demonetisation": "demonetization",
        }
        super().__init__(rule)


Cache = {}


cpdef str unidecode_weak(str string):
    """Transliterate an Unicode object into an ASCII string
    >>> unidecode(u"\u5317\u4EB0")
    "Bei Jing "
    """

    cdef list retval = []
    cdef int i = 0
    cdef int n = len(string)
    cdef str char

    for i in range(n):
        char = string[i]
        codepoint = ord(char)

        if codepoint < 0x80: # Basic ASCII
            retval.append(char)
            continue

        if codepoint > 0xeffff:
            continue  # Characters in Private Use Area and above are ignored

        section = codepoint >> 8   # Chop off the last two hex digits
        position = codepoint % 256 # Last two hex digits

        try:
            table = Cache[section]
        except KeyError:
            try:
                mod = __import__('unidecode.x%03x'%(section), [], [], ['data'])
            except ImportError:
                Cache[section] = None
                continue   # No match: ignore this character and carry on.

            Cache[section] = table = mod.data

        if table and len(table) > position:
            if table[position] == '[?]':
                retval.append(' ' + char + ' ')
            else:
                retval.append(table[position])

    return ''.join(retval)
