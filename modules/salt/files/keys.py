'''
runner: do basic operations on keys for a specified minion
'''

import logging
import salt.key


def accept(minion):
    '''
    accept salt key for the specified minion
    '''
    pending = 'minions_pre'

    key = salt.key.Key(__opts__)
    matches = key.name_match(minion)
    keys = {}
    if pending in matches:
        keys[pending] = matches[pending]
    if not keys:
        log = logging.getLogger(__name__)
        log.warn("No unsigned key found for minion: {0}".format(minion))
        result = 'missing'
    else:
        key.accept(match_dict=keys)
        result = 'done'
    print result
    return result

def status(minion):
    '''
    return status of key for specified minion
    '''
    pending = 'minions_pre'
    accepted = 'minions'
    key = salt.key.Key(__opts__)
    matches = key.name_match(minion)
    if pending in matches:
        result =  'pending'
    elif accepted in matches:
        result = 'accepted'
    else:
        result = 'missing'
    print result
    return result

def delete(minion):
    '''
    delete salt key for the specified minion
    '''
    pending = 'minions_pre'
    accepted = 'minions'

    key = salt.key.Key(__opts__)
    matches = key.name_match(minion)
    keys = {}
    if pending in matches:
        keys[pending] = matches[pending]
    if accepted in matches:
        keys[accepted] = matches[accepted]
    if not keys:
        log = logging.getLogger(__name__)
        log.warn("No key to delete found for minion: {0}".format(minion))
        result = 'missing'
    else:
        key.delete_key(match_dict=keys)
        result = 'done'
    print result
    return result
