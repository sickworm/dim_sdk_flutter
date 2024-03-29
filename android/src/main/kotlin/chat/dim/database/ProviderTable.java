/* license: https://mit-license.org
 * ==============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2019 Albert Moky
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * ==============================================================================
 */
package chat.dim.database;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import chat.dim.mkm.ID;

public class ProviderTable extends ExternalStorage {

    // "/sdcard/chat.dim.sechat/dim/{SP_ADDRESS}/config.js"

    private String getConfigFilePath(ID sp) {
        return root + "/dim/" + sp.address + "/config.js";
    }

    @SuppressWarnings("unchecked")
    Map<String, Object> getProviderConfig(ID sp) {
        String path = getConfigFilePath(sp);
        Map<String, Object> config = null;
        try {
            config = (Map<String, Object>) readJSON(path);
        } catch (IOException e) {
            //e.printStackTrace();
        }
        if (config == null) {
            config = new HashMap<>();
            config.put("ID", sp);
        }
        return config;
    }

    // "/sdcard/chat.dim.sechat/dim/service_providers.js"

    private static String getProvidersFilePath() {
        return root + "/dim/service_providers.js";
    }

    @SuppressWarnings("unchecked")
    List<String> allProviders() {
        String path = getProvidersFilePath();
        try {
            return (List<String>) readJSON(path);
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }

    boolean saveProviders(List<String> providers) {
        String path = getProvidersFilePath();
        try {
            return writeJSON(providers, path);
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }
}
