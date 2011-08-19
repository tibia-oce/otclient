#ifndef SPRITEMANAGER_H
#define SPRITEMANAGER_H

#include "declarations.h"
#include <framework/graphics/texture.h>

class SpriteManager
{
public:
    SpriteManager();

    bool load(const std::string& filename);
    void unload();

    uint32 getSignature() { return m_signature; }
    int getSpritesCount() { return m_spritesCount; }

    TexturePtr getSpriteTexture(int id);
    TexturePtr getSpriteMask(int id, SpriteMask mask);

private:
    TexturePtr loadSprite(int id);

    uint32 m_signature;
    uint16 m_spritesCount;
    std::stringstream m_fin;
    std::vector<TexturePtr> m_sprites;
    TexturePtr m_transparentSprite;
};

extern SpriteManager g_sprites;

#endif
