#
# Copyright 2017 Preetam J. D'Souza
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

_NUM_TESTS=0
_NUM_PASS=0

_test_pass() {
    echo "[ PASS ]"
}

_test_fail () {
    echo "[ FAIL ]"
}

techo () {
    printf "  %-60s" "$@"
}

treport () {
    echo
    echo "$_NUM_PASS of $_NUM_TESTS tests passed."
}

texit () {
    treport
    exit $(( _NUM_TESTS - _NUM_PASS ))
}

tassert_eq () {
    local readonly expected="$1"
    local readonly value="$2"

    (( ++_NUM_TESTS ))
    if [ "$expected" = "$value" ] ; then
        (( ++_NUM_PASS ))
        _test_pass
    else
        _test_fail
    fi
}
